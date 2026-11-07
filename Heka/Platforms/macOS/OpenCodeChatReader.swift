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
        guard let records = database.rows("""
            SELECT id, \(modern ? "type" : "json_extract(data, '$.role')") AS role,
                substr(json_extract(data, '$.text'), 1, 65536) AS text
            FROM (SELECT * FROM \(table) WHERE session_id = ? ORDER BY \(descending) LIMIT 200)
            ORDER BY \(order)
            """, bindings: [sessionID]),
              let parts = database.rows("""
            SELECT p.message_id, \(modern ? "CAST(p.ordinal AS TEXT)" : "p.id") AS part_id, substr(p.data, 1, 1048576) AS data
            FROM \(partTable) p JOIN
                (SELECT * FROM \(table) WHERE session_id = ? ORDER BY \(descending) LIMIT 200) m ON m.id = p.message_id
            WHERE json_extract(p.data, '$.type') IN ('text', 'tool')
            ORDER BY \(modern ? "m.seq DESC, p.ordinal DESC" : "m.time_created DESC, m.id DESC, p.id DESC") LIMIT 200
            """, bindings: [sessionID]) else { return messages }
        let grouped = Dictionary(grouping: parts.reversed(), by: { $0["message_id"] ?? "" })
        var log = ChatMessageLog()
        for record in records {
            guard let id = record["id"], let role = record["role"], ["user", "assistant"].contains(role) else { continue }
            if modern, role == "user" { log.addText(record["text"] ?? "", id: id, kind: .input) }
            for part in grouped[id] ?? [] {
                let partID = id + ":" + (part["part_id"] ?? "")
                let object = Self.object(part["data"])
                if object.isEmpty, (part["data"]?.utf8.count ?? 0) >= 1_048_576 {
                    log.addText(String(localized: "Result too large to display."), id: partID, kind: .notice)
                } else {
                    Self.consume(object, id: partID, role: role, log: &log)
                }
            }
        }
        log.trim()
        messages = log.messages
        stamps = current
        return messages
    }

    private static func object(_ text: String?) -> [String: Any] {
        guard let text else { return [:] }
        return (try? JSONSerialization.jsonObject(with: Data(text.utf8))) as? [String: Any] ?? [:]
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
