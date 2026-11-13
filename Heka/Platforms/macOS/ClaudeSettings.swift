import Foundation

actor ClaudeSettings {
    private struct Cached {
        let modified: Date?
        let options: AgentOptionsReport
    }

    private let files: [URL]
    private var cache: [URL: Cached] = [:]

    init(configDirectory: URL, projectDirectory: String?) {
        files = Self.files(configDirectory: configDirectory, projectDirectory: projectDirectory)
    }

    static func files(configDirectory: URL, projectDirectory: String?) -> [URL] {
        let project = projectDirectory.map { URL(fileURLWithPath: $0).appendingPathComponent(".claude") }
        return [project?.appendingPathComponent("settings.local.json"), project?.appendingPathComponent("settings.json"),
                configDirectory.appendingPathComponent("settings.json")].compactMap(\.self)
    }

    func agentOptions() -> AgentOptionsReport {
        files.reduce(AgentOptionsReport()) { options, file in options.filling(read(file)) }
    }

    private func read(_ file: URL) -> AgentOptionsReport {
        let modified = (try? FileManager.default.attributesOfItem(atPath: file.path))?[.modificationDate] as? Date
        if let cached = cache[file], cached.modified == modified { return cached.options }
        let options = modified == nil ? AgentOptionsReport() : Self.parse(file)
        cache[file] = Cached(modified: modified, options: options)
        return options
    }

    private static func parse(_ file: URL) -> AgentOptionsReport {
        guard let data = try? Data(contentsOf: file),
              let settings = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return AgentOptionsReport() }
        return AgentOptionsReport(model: (settings["model"] as? String).map(AgentModel.init(reported:)),
                                  effort: (settings["effortLevel"] as? String).flatMap { AgentEffort(rawValue: $0.lowercased()) })
    }
}
