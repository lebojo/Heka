import Foundation

actor OpenCodeChatReader {
    private struct Stamp: Equatable {
        let inode: UInt64?
        let size: UInt64?
        let modified: Date?

        init(_ url: URL) {
            let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
            inode = attributes?[.systemFileNumber] as? UInt64
            size = attributes?[.size] as? UInt64
            modified = attributes?[.modificationDate] as? Date
        }
    }

    private let sessionID: String
    private var messages: [SessionMessage] = []
    private var stamps: [Stamp]?

    init(sessionID: String) { self.sessionID = sessionID }

    func read(_ url: URL) -> [SessionMessage] {
        let current = [Stamp(url), Stamp(URL(fileURLWithPath: url.path + "-wal"))]
        guard current != stamps else { return messages }
        guard let database = SessionDatabase(url) else { return messages }
        let modern = database.rows("SELECT id FROM session_v2 WHERE id = ?", bindings: [sessionID])?.isEmpty == false
        let table = modern ? "session_message" : "message"
        let partTable = modern ? "session_part" : "part"
        let order = modern ? "seq" : "time_created, id"
        let descending = modern ? "seq DESC" : "time_created DESC, id DESC"
        let inlineContent = """
            CASE WHEN content_size = 0 THEN NULL WHEN content_size > 1048576 THEN ''
                WHEN content_size <= 32768 THEN json_extract(data, '$.content')
                WHEN SUM(CASE WHEN content_size BETWEEN 32769 AND 1048576 THEN content_size ELSE 0 END) OVER (ORDER BY seq DESC) <= 8388608
                THEN json_extract(data, '$.content') ELSE '' END
            """
        let hasParts = database.rows("SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?", bindings: [partTable])?.isEmpty == false
        guard let records = database.rows("""
            SELECT id, \(modern ? "type" : "json_extract(data, '$.role')") AS role,
                substr(json_extract(data, '$.text'), 1, 65536) AS text,
                \(modern ? inlineContent : "NULL") AS content
            FROM (SELECT *, \(modern ? "CASE WHEN type = 'assistant' THEN coalesce(length(json_extract(data, '$.content')), 0) ELSE 0 END" : "0") AS content_size
                FROM \(table) WHERE session_id = ? ORDER BY \(descending) LIMIT 200)
            ORDER BY \(order)
            """, bindings: [sessionID]),
              let parts = hasParts ? database.rows("""
            SELECT p.message_id, \(modern ? "CAST(p.ordinal AS TEXT)" : "p.id") AS part_id, \(modern ? "p.call_id" : "NULL") AS call_id, substr(p.data, 1, 1048576) AS data
            FROM \(partTable) p JOIN
                (SELECT * FROM \(table) WHERE session_id = ? ORDER BY \(descending) LIMIT 200) m ON m.id = p.message_id
            WHERE json_extract(p.data, '$.type') IN ('text', 'tool')
            ORDER BY \(modern ? "m.seq DESC, p.ordinal DESC" : "m.time_created DESC, m.id DESC, p.id DESC") LIMIT 200
            """, bindings: [sessionID]) : [] else { return messages }
        let grouped = Dictionary(grouping: parts.reversed(), by: { $0["message_id"] ?? "" })
        var log = ChatMessageLog()
        for record in records {
            guard let id = record["id"], let role = record["role"], ["user", "assistant"].contains(role) else { continue }
            if modern, role == "user" { log.addText(record["text"] ?? "", id: id, kind: .input) }
            let rows = grouped[id] ?? []
            for part in rows {
                let partID = id + ":" + (part["part_id"] ?? "")
                let object: [String: Any] = Self.json(part["data"]) ?? [:]
                if object.isEmpty, (part["data"]?.utf8.count ?? 0) >= 1_048_576 {
                    log.addText(String(localized: "Result too large to display."), id: partID, kind: .notice)
                } else {
                    Self.consume(object, id: partID, role: role, log: &log)
                }
            }
            guard role == "assistant", let content = record["content"] else { continue }
            guard let inline: [[String: Any]] = Self.json(content) else {
                log.addText(String(localized: "Result too large to display."), id: id + ":inline", kind: .notice)
                continue
            }
            let storedTools = Set(rows.compactMap { $0["call_id"] })
            for (index, part) in inline.enumerated() {
                let toolID = part["type"] as? String == "tool" ? part["id"] as? String : nil
                if let toolID, storedTools.contains(toolID) { continue }
                Self.consume(part, id: id + ":inline:" + (toolID ?? String(index)), role: role, log: &log)
            }
        }
        log.trim()
        messages = log.messages
        stamps = current
        return messages
    }

    private static func json<Value>(_ text: String?) -> Value? {
        guard let text else { return nil }
        return (try? JSONSerialization.jsonObject(with: Data(text.utf8))) as? Value
    }

    private static func consume(_ part: [String: Any], id: String, role: String, log: inout ChatMessageLog) {
        switch part["type"] as? String {
        case "text" where part["synthetic"] as? Bool != true && part["ignored"] as? Bool != true:
            log.addText(part["text"] as? String ?? "", id: id, kind: role == "user" ? .input : .assistant)
        case "tool" where role == "assistant":
            let state = part["state"] as? [String: Any] ?? [:]
            let input = state["input"] as? [String: Any] ?? [:]
            log.startTool(id, name: part["name"] as? String ?? part["tool"] as? String ?? String(localized: "Tool"),
                          detail: ChatMessageLog.summary(of: input))
            switch state["status"] as? String {
            case "completed":
                log.finishTool(id, output: state["output"] as? String ?? ChatMessageLog.text(state["content"]), failed: false)
            case "error":
                let error = state["error"] as? String ?? (state["error"] as? [String: Any])?["message"] as? String
                log.finishTool(id, output: error ?? ChatMessageLog.text(state["content"]), failed: true)
            default: break
            }
        default: break
        }
    }
}
