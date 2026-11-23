import Foundation

enum SlashCommandDiscovery {
    static func commands(for source: SessionChatSource, directory: String?, configDirectory: URL?) async -> [SlashCommand] {
        let custom = await customCommands(for: source, directory: directory, home: URL.homeDirectory, configDirectory: configDirectory)
        return merged(source.slashCommands, custom)
    }

    static func merged(_ builtIn: [SlashCommand], _ custom: [SlashCommand]) -> [SlashCommand] {
        var names = Set(builtIn.map(\.name))
        return builtIn + custom.filter { names.insert($0.name).inserted }
    }

    @concurrent static func customCommands(for source: SessionChatSource, directory: String?, home: URL,
                                          configDirectory: URL? = nil) async -> [SlashCommand] {
        let project = directory.map { URL(fileURLWithPath: $0) }
        switch source {
        case .claude:
            let roots = [project?.appendingPathComponent(".claude"), configDirectory ?? home.appendingPathComponent(".claude")].compactMap(\.self)
            return roots.flatMap { commandFiles(in: $0.appendingPathComponent("commands")) }
                + roots.flatMap { skills(in: $0.appendingPathComponent("skills")) }
        case .codex:
            let codex = configDirectory ?? home.appendingPathComponent(".codex")
            return commandFiles(in: codex.appendingPathComponent("prompts"), prefix: "prompts:")
        case .copilot:
            let projectRoots = [".github", ".claude", ".agents"].compactMap { project?.appendingPathComponent($0) }
            let personalRoots = [configDirectory ?? home.appendingPathComponent(".copilot"), home.appendingPathComponent(".agents")]
            return (projectRoots + personalRoots).flatMap { skills(in: $0.appendingPathComponent("skills")) }
        case .openCode:
            let config = configDirectory ?? home.appendingPathComponent(".config/opencode")
            let openCodeRoots = [project?.appendingPathComponent(".opencode"), config].compactMap(\.self)
            let sharedRoots = [project?.appendingPathComponent(".claude"), project?.appendingPathComponent(".agents"),
                               home.appendingPathComponent(".claude"), home.appendingPathComponent(".agents")].compactMap(\.self)
            let commands = openCodeRoots.flatMap { root in
                ["command", "commands"].flatMap { openCodeCommandFiles(in: root.appendingPathComponent($0)) }
            }
            let openCodeSkills = openCodeRoots.flatMap { root in ["skill", "skills"].flatMap { skills(in: root.appendingPathComponent($0)) } }
            return commands + openCodeSkills + sharedRoots.flatMap { skills(in: $0.appendingPathComponent("skills")) }
        case .terminal:
            return []
        }
    }

    static func command(name: String, markdown: String) -> SlashCommand? {
        let metadata = frontMatter(of: markdown)
        guard metadata["user-invocable"] != "false" else { return nil }
        return SlashCommand(name: metadata["name"] ?? name, summary: summary(of: markdown, metadata: metadata), argument: metadata["argument-hint"])
    }

    static func openCodeCommand(path: [String], markdown: String) -> SlashCommand {
        SlashCommand(name: path.joined(separator: "/"), summary: summary(of: markdown, metadata: frontMatter(of: markdown)), argument: nil)
    }

    private static func summary(of markdown: String, metadata: [String: String]) -> String {
        metadata["description"] ?? firstBodyLine(of: markdown) ?? String(localized: "Custom command")
    }

    private static func commandFiles(in folder: URL, prefix: String = "") -> [SlashCommand] {
        markdownFiles(in: folder).compactMap { file in
            guard let markdown = try? String(contentsOf: file, encoding: .utf8) else { return nil }
            return command(name: prefix + file.deletingPathExtension().lastPathComponent, markdown: markdown)
        }
    }

    private static func openCodeCommandFiles(in folder: URL) -> [SlashCommand] {
        let paths = (try? FileManager.default.subpathsOfDirectory(atPath: folder.path)) ?? []
        return paths.filter { $0.hasSuffix(".md") }.sorted().compactMap { path in
            guard let markdown = try? String(contentsOf: folder.appendingPathComponent(path), encoding: .utf8) else { return nil }
            return openCodeCommand(path: (String(path.dropLast(3)) as NSString).pathComponents, markdown: markdown)
        }
    }

    private static func markdownFiles(in folder: URL) -> [URL] {
        guard let files = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: nil) else { return [] }
        return files.compactMap { $0 as? URL }
            .filter { $0.pathExtension == "md" }
            .sorted { $0.path < $1.path }
    }

    private static func skills(in folder: URL) -> [SlashCommand] {
        let folders = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        return folders.sorted { $0.path < $1.path }.compactMap { skill in
            guard let markdown = try? String(contentsOf: skill.appendingPathComponent("SKILL.md"), encoding: .utf8) else { return nil }
            return command(name: skill.lastPathComponent, markdown: markdown)
        }
    }

    private static func rawLines(of markdown: String) -> [String] {
        markdown.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: .newlines)
    }

    private static func lines(of markdown: String) -> [String] {
        rawLines(of: markdown).map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private static func frontMatter(of markdown: String) -> [String: String] {
        let raw = rawLines(of: markdown)
        let lines = lines(of: markdown)
        guard lines.first == "---", let end = lines.dropFirst().firstIndex(of: "---") else { return [:] }
        var metadata: [String: String] = [:]
        var index = 1
        while index < end {
            let line = lines[index]
            index += 1
            guard !raw[index - 1].hasPrefix(" "), let colon = line.firstIndex(of: ":") else { continue }
            let key = line[..<colon].trimmingCharacters(in: .whitespaces)
            var value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            if value.hasPrefix(">") || value.hasPrefix("|") {
                let block = raw[index..<end].prefix { $0.isEmpty || $0.first?.isWhitespace == true }
                index += block.count
                let parts = block.map { $0.trimmingCharacters(in: .whitespaces) }
                value = value.hasPrefix(">") ? parts.filter { !$0.isEmpty }.joined(separator: " ") : parts.joined(separator: "\n")
            }
            value = value.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "\"'")))
            if !value.isEmpty { metadata[key] = value }
        }
        return metadata
    }

    private static func firstBodyLine(of markdown: String) -> String? {
        let lines = lines(of: markdown)
        let body = lines.first == "---" ? Array(lines.drop { $0 != "---" }.dropFirst().drop { $0 != "---" }.dropFirst()) : lines
        return body.first { !$0.isEmpty && !$0.hasPrefix("#") }.map { String($0.prefix(80)) }
    }
}
