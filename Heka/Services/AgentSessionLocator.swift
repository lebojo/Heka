import Foundation

enum AgentSessionLocator {
    struct Match: Equatable {
        let id: String
        let path: String
    }

    static func explicitSession(in arguments: [String], agent: ConversationAgent) -> String? {
        let flags = agent == .codex ? ["resume"] : ["--session", "-s", "--resume"]
        for (index, argument) in arguments.enumerated() {
            for flag in flags {
                let value = argument.hasPrefix(flag + "=") ? String(argument.dropFirst(flag.count + 1))
                    : (argument == flag && index + 1 < arguments.count ? arguments[index + 1] : nil)
                if let value, AgentConversation.isValidSessionID(value) { return value }
            }
        }
        return nil
    }

    static func codex(home: URL, directory: String, startedAt: Date, sessionID: String?) -> Match? {
        let files = (try? FileManager.default.contentsOfDirectory(at: home, includingPropertiesForKeys: nil)) ?? []
        let databases = files.filter { $0.lastPathComponent.hasPrefix("state_") && $0.pathExtension == "sqlite" }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedDescending }
        for url in databases {
            guard let database = SessionDatabase(url) else { continue }
            let query = sessionID == nil
                ? "SELECT id, rollout_path FROM threads WHERE cwd = ? AND created_at >= ? AND archived = 0"
                : "SELECT id, rollout_path FROM threads WHERE id = ?"
            let bindings = sessionID.map { [$0] } ?? [directory, String(Int(startedAt.timeIntervalSince1970) - 2)]
            guard let rows = database.rows(query, bindings: bindings) else { continue }
            let candidates = rows.compactMap { row -> Match? in
                guard let id = row["id"], let path = row["rollout_path"], FileManager.default.fileExists(atPath: path) else { return nil }
                return Match(id: id, path: path)
            }
            // Never attach a different terminal's conversation just because it was updated last.
            return candidates.count == 1 ? candidates[0] : nil
        }
        return nil
    }

    static func openCode(database url: URL, directory: String, startedAt: Date, sessionID: String?) -> Match? {
        guard let database = SessionDatabase(url) else { return nil }
        for table in ["session_v2", "session"] {
            let query = sessionID == nil
                ? "SELECT id FROM \(table) WHERE directory = ? AND time_created >= ? AND parent_id IS NULL AND time_archived IS NULL"
                : "SELECT id FROM \(table) WHERE id = ?"
            let bindings = sessionID.map { [$0] } ?? [directory, String(Int64((startedAt.timeIntervalSince1970 - 2) * 1000))]
            guard let rows = database.rows(query, bindings: bindings), !rows.isEmpty else { continue }
            guard rows.count == 1, let id = rows[0]["id"] else { return nil }
            return Match(id: id, path: url.path)
        }
        return nil
    }
}
