import Foundation

enum SlashCommandDiscovery {
    static func commands(for source: SessionChatSource, directory: String?) async -> [SlashCommand] {
        let custom = await customCommands(for: source, directory: directory,
                                          home: URL.homeDirectory)
        return merged(source.slashCommands, custom)
    }

    static func merged(_ builtIn: [SlashCommand], _ custom: [SlashCommand]) -> [SlashCommand] {
        var names = Set(builtIn.map(\.name))
        return builtIn + custom.filter { names.insert($0.name).inserted }
    }

    @concurrent static func customCommands(for source: SessionChatSource, directory: String?, home: URL) async -> [SlashCommand] {
        let project = directory.map { URL(fileURLWithPath: $0) }
        switch source {
        case .claude:
            let roots = [project, home].compactMap { $0?.appendingPathComponent(".claude") }
            return roots.flatMap { commandFiles(in: $0.appendingPathComponent("commands")) }
                + roots.flatMap { skills(in: $0.appendingPathComponent("skills")) }
        case .codex:
            return commandFiles(in: home.appendingPathComponent(".codex/prompts"), prefix: "prompts:")
        case .terminal, .copilot, .openCode:
            return []
        }
    }

    static func command(name: String, markdown: String) -> SlashCommand? {
        let metadata = frontMatter(of: markdown)
        guard metadata["user-invocable"] != "false" else { return nil }
        let summary = metadata["description"] ?? firstBodyLine(of: markdown) ?? String(localized: "Custom command")
        return SlashCommand(name: metadata["name"] ?? name, summary: summary, argument: metadata["argument-hint"])
    }

    private static func commandFiles(in folder: URL, prefix: String = "") -> [SlashCommand] {
        guard let files = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: nil) else { return [] }
        return files.compactMap { $0 as? URL }
            .filter { $0.pathExtension == "md" }
            .sorted { $0.path < $1.path }
            .compactMap { file in
                guard let markdown = try? String(contentsOf: file, encoding: .utf8) else { return nil }
                return command(name: prefix + file.deletingPathExtension().lastPathComponent, markdown: markdown)
            }
    }

    private static func skills(in folder: URL) -> [SlashCommand] {
        let folders = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        return folders.sorted { $0.path < $1.path }.compactMap { skill in
            guard let markdown = try? String(contentsOf: skill.appendingPathComponent("SKILL.md"), encoding: .utf8) else { return nil }
            return command(name: skill.lastPathComponent, markdown: markdown)
        }
    }

    private static func frontMatter(of markdown: String) -> [String: String] {
        let lines = markdown.split(separator: "\n", omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: .whitespaces) }
        guard lines.first == "---", let end = lines.dropFirst().firstIndex(of: "---") else { return [:] }
        return lines[1..<end].reduce(into: [:]) { metadata, line in
            guard let colon = line.firstIndex(of: ":") else { return }
            let key = line[..<colon].trimmingCharacters(in: .whitespaces)
            let value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces.union(CharacterSet(charactersIn: "\"'")))
            if !value.isEmpty { metadata[key] = value }
        }
    }

    private static func firstBodyLine(of markdown: String) -> String? {
        let lines = markdown.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        let body = lines.first == "---" ? Array(lines.drop { $0 != "---" }.dropFirst().drop { $0 != "---" }.dropFirst()) : lines
        return body.first { !$0.isEmpty && !$0.hasPrefix("#") }.map { String($0.prefix(80)) }
    }
}
