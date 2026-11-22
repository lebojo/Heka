import Foundation

enum JSONLines {
    @discardableResult
    static func forEach(_ url: URL, from offset: Int = 0, skippingPartialLine: Bool = false, limit: Int, _ body: (Data) -> Bool) -> Int {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return offset }
        defer { try? handle.close() }
        var skipping = skippingPartialLine && offset > 0
        var consumed = skipping ? offset - 1 : offset
        guard (try? handle.seek(toOffset: UInt64(consumed))) != nil else { return offset }
        var buffer = Data()
        var read = 0
        while read < limit {
            guard let chunk = try? handle.read(upToCount: 65_536), !chunk.isEmpty else {
                if !buffer.isEmpty, !skipping { _ = body(buffer) }
                return consumed
            }
            read += chunk.count
            buffer.append(chunk)
            var start = buffer.startIndex
            while let newline = buffer[start...].firstIndex(of: 0x0A) {
                let line = Data(buffer[start..<newline])
                start = buffer.index(after: newline)
                consumed += line.count + 1
                if skipping {
                    skipping = false
                    continue
                }
                if !line.isEmpty, !body(line) { return consumed }
            }
            buffer = Data(buffer[start...])
        }
        return consumed
    }

    static func line(_ line: Data, contains marker: String) -> Bool {
        line.range(of: Data(marker.utf8)) != nil
    }
}

enum ConversationTitle {
    static func clean(_ text: String?) -> String? {
        guard let text else { return nil }
        let words = text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        guard !words.isEmpty, !words.hasPrefix("<") else { return nil }
        return words.count > 120 ? String(words.prefix(119)) + "…" : words
    }
}

struct MessageContent: Decodable {
    let text: String?

    private struct Block: Decodable {
        let type: String?
        let text: String?
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self) {
            self.text = text
        } else {
            let blocks = (try? container.decode([Block].self)) ?? []
            text = blocks.first { $0.type == "text" || $0.type == "input_text" }?.text
        }
    }
}

struct ClaudeTranscript: Equatable, Sendable {
    var cwd: String?
    var customTitle: String?
    var aiTitle: String?
    var firstPrompt: String?
    private(set) var scannedLength = 0

    var title: String? { customTitle ?? aiTitle ?? firstPrompt }
    private var hasHead: Bool { cwd != nil && (firstPrompt != nil || customTitle != nil || aiTitle != nil) }

    private struct Line: Decodable {
        let type: String?
        let cwd: String?
        let aiTitle: String?
        let customTitle: String?
        let isMeta: Bool?
        let message: Message?
    }

    private struct Message: Decodable {
        let content: MessageContent?
    }

    static func configDirectory(home: URL = FileManager.default.homeDirectoryForCurrentUser,
                                environment: [String: String] = ProcessInfo.processInfo.environment) -> URL {
        environment["CLAUDE_CONFIG_DIR"].map { URL(fileURLWithPath: $0) } ?? home.appendingPathComponent(".claude")
    }

    static func configDirectory(ofJournal journal: URL) -> URL {
        journal.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    }

    static func directoryName(for path: String) -> String {
        String(path.utf16.map { unit in
            guard let scalar = Unicode.Scalar(unit), scalar.isASCII, CharacterSet.alphanumerics.contains(scalar) else { return "-" }
            return Character(scalar)
        })
    }

    static func directories(for path: String, in projects: URL) -> [URL] {
        let name = directoryName(for: path)
        let exact = projects.appendingPathComponent(name, isDirectory: true)
        if FileManager.default.fileExists(atPath: exact.path) { return [exact] }
        guard name.count > 200 else { return [] }
        let prefix = String(name.prefix(200))
        let folders = (try? FileManager.default.contentsOfDirectory(at: projects, includingPropertiesForKeys: nil)) ?? []
        return folders.filter { $0.lastPathComponent.hasPrefix(prefix) }
    }

    static func url(sessionID: String, cwd: String, projects: URL) -> URL {
        let file = sessionID + ".jsonl"
        let candidates = directories(for: cwd, in: projects).map { $0.appendingPathComponent(file) }
        return candidates.first { FileManager.default.fileExists(atPath: $0.path) }
            ?? projects.appendingPathComponent(directoryName(for: cwd), isDirectory: true).appendingPathComponent(file)
    }

    static func read(_ url: URL, continuing previous: ClaudeTranscript? = nil,
                     headLimit: Int = 8_388_608, tailLength: Int = 1_048_576) -> ClaudeTranscript {
        var transcript = previous ?? ClaudeTranscript()
        let headEnd = transcript.readHead(of: url, limit: headLimit)
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        let tailStart = max(headEnd, size - tailLength)
        if tailStart > headEnd { transcript.readTitles(of: url, from: headEnd, to: tailStart) }
        transcript.scannedLength = JSONLines.forEach(url, from: tailStart, skippingPartialLine: tailStart > headEnd, limit: .max) { line in
            transcript.consume(line)
            return true
        }
        return transcript
    }

    private mutating func readHead(of url: URL, limit: Int) -> Int {
        guard !hasHead else { return scannedLength }
        return JSONLines.forEach(url, from: scannedLength, limit: limit) { line in
            consume(line)
            return !hasHead
        }
    }

    private mutating func readTitles(of url: URL, from start: Int, to end: Int) {
        JSONLines.forEach(url, from: start, limit: end - start) { line in
            if JSONLines.line(line, contains: "-title\"") { consume(line) }
            return true
        }
    }

    private mutating func consume(_ data: Data) {
        let wanted = JSONLines.line(data, contains: "\"ai-title\"") || JSONLines.line(data, contains: "\"custom-title\"")
            || (cwd == nil && JSONLines.line(data, contains: "\"cwd\""))
            || (firstPrompt == nil && JSONLines.line(data, contains: "\"type\":\"user\""))
        guard wanted, let line = try? JSONDecoder().decode(Line.self, from: data) else { return }
        if cwd == nil { cwd = line.cwd }
        switch line.type {
        case "ai-title": aiTitle = ConversationTitle.clean(line.aiTitle) ?? aiTitle
        case "custom-title": customTitle = ConversationTitle.clean(line.customTitle) ?? customTitle
        case "user" where firstPrompt == nil && line.isMeta != true:
            firstPrompt = ConversationTitle.clean(line.message?.content?.text)
        default: break
        }
    }
}

struct CodexRollout: Equatable, Sendable {
    let sessionID: String
    let cwd: String
    let firstPrompt: String?

    private struct Header: Decodable {
        let type: String
        let payload: Payload
    }

    private struct Payload: Decodable {
        let id: String
        let sessionID: String?
        let cwd: String

        enum CodingKeys: String, CodingKey {
            case id, cwd
            case sessionID = "session_id"
        }
    }

    private struct Item: Decodable {
        let type: String?
        let payload: ItemPayload?
    }

    private struct ItemPayload: Decodable {
        let type: String?
        let role: String?
        let content: MessageContent?
    }

    static func read(_ url: URL, limit: Int = 2_097_152) -> CodexRollout? {
        var header: Payload?
        var prompt: String?
        JSONLines.forEach(url, limit: limit) { line in
            guard header != nil else {
                guard let decoded = try? JSONDecoder().decode(Header.self, from: line), decoded.type == "session_meta",
                      (decoded.payload.sessionID ?? decoded.payload.id) == decoded.payload.id else { return false }
                header = decoded.payload
                return true
            }
            guard JSONLines.line(line, contains: "\"role\":\"user\""),
                  let item = try? JSONDecoder().decode(Item.self, from: line),
                  item.type == "response_item", item.payload?.type == "message", item.payload?.role == "user",
                  let text = item.payload?.content?.text, !text.hasPrefix("# AGENTS.md") else { return true }
            prompt = ConversationTitle.clean(text)
            return prompt == nil
        }
        guard let header else { return nil }
        return CodexRollout(sessionID: header.id, cwd: header.cwd, firstPrompt: prompt)
    }

    static func titles(in index: URL) -> [String: String] {
        struct Entry: Decodable {
            let id: String
            let threadName: String?

            enum CodingKeys: String, CodingKey {
                case id
                case threadName = "thread_name"
            }
        }
        var titles: [String: String] = [:]
        JSONLines.forEach(index, limit: 16_777_216) { line in
            if let entry = try? JSONDecoder().decode(Entry.self, from: line), let title = ConversationTitle.clean(entry.threadName) {
                titles[entry.id] = title
            }
            return true
        }
        return titles
    }
}

struct CopilotWorkspace: Equatable, Sendable {
    let cwd: String?
    let title: String?

    private struct Event: Decodable {
        struct Payload: Decodable {
            let content: MessageContent?
        }
        let type: String?
        let data: Payload?
    }

    static func read(_ url: URL) -> CopilotWorkspace? {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let fields = YAMLFields.parse(text)
        return CopilotWorkspace(cwd: fields["cwd"], title: ConversationTitle.clean(fields["name"]) ?? ConversationTitle.clean(fields["summary"]))
    }

    static func firstPrompt(in events: URL, limit: Int = 2_097_152) -> String? {
        var prompt: String?
        JSONLines.forEach(events, limit: limit) { line in
            guard JSONLines.line(line, contains: "\"user.message\""),
                  let event = try? JSONDecoder().decode(Event.self, from: line), event.type == "user.message" else { return true }
            prompt = ConversationTitle.clean(event.data?.content?.text)
            return prompt == nil
        }
        return prompt
    }
}

enum YAMLFields {
    static func parse(_ text: String) -> [String: String] {
        var fields: [String: String] = [:]
        var key: String?
        var lines: [String] = []
        for line in text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline) {
            if let first = line.first, !first.isWhitespace, first != "#", first != "-", let colon = line.firstIndex(of: ":") {
                if let key { fields[key] = scalar(lines) }
                key = String(line[..<colon])
                lines = [line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)]
            } else if key != nil {
                lines.append(line.trimmingCharacters(in: .whitespaces))
            }
        }
        if let key { fields[key] = scalar(lines) }
        return fields
    }

    private static func scalar(_ lines: [String]) -> String? {
        guard let head = lines.first else { return nil }
        if head.hasPrefix("|") || head.hasPrefix(">") {
            return lines.dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let value = ([head] + lines.dropFirst().filter { !$0.isEmpty }).joined(separator: " ")
        if value.count > 1, value.hasPrefix("'"), value.hasSuffix("'") {
            return String(value.dropFirst().dropLast()).replacingOccurrences(of: "''", with: "'")
        }
        if value.count > 1, value.hasPrefix("\""), value.hasSuffix("\"") {
            return (try? JSONDecoder().decode(String.self, from: Data(value.utf8))) ?? String(value.dropFirst().dropLast())
        }
        let plain = lines.map(withoutComment).filter { !$0.isEmpty }.joined(separator: " ")
        return ["", "~", "null"].contains(plain) ? nil : plain
    }

    private static func withoutComment(_ line: String) -> String {
        var previous: Character = " "
        for index in line.indices {
            if line[index] == "#", previous.isWhitespace { return line[..<index].trimmingCharacters(in: .whitespaces) }
            previous = line[index]
        }
        return line
    }
}
