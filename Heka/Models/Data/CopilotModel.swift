import Foundation

struct CopilotModel: Codable, Hashable, Identifiable, Sendable {
    static let automatic = CopilotModel(id: "auto")

    static let catalog: [CopilotModel] = [
        "claude-sonnet-5.5", "claude-sonnet-5", "claude-fable-5.2", "claude-fable-5.1", "claude-fable-5",
        "claude-opus-5.5", "claude-opus-5", "claude-opus-4.8", "claude-opus-4.8-fast", "claude-sonnet-4.6",
        "claude-haiku-5.5", "claude-haiku-4.5",
        "gpt-6.1-sol", "gpt-6.1-terra", "gpt-6-sol", "gpt-6-luna", "gpt-6-astra",
        "gpt-5.6-sol", "gpt-5.6-terra", "gpt-5.6-luna", "gpt-5.3-codex",
        "mai-code-1.1-flash", "gemini-4-carbon", "gemini-4-argon", "gemini-3.8-flash",
        "grok-4.7", "grok-4.6", "kimi-k3",
    ].map(CopilotModel.init(id:))

    let id: String

    init(id: String) {
        self.id = id
    }

    init?(reported name: String?) {
        guard let name = name?.trimmingCharacters(in: .whitespaces).lowercased(), !name.isEmpty else { return nil }
        id = name == "fusion" ? Self.automatic.id : name
    }

    var isAutomatic: Bool { self == .automatic }

    var title: String {
        guard !isAutomatic else { return String(localized: "Auto", comment: "Copilot model menu option that lets Copilot pick the model") }
        return id.split(separator: "-").reduce(into: [String]()) { words, part in
            if words.last == "GPT" {
                words[words.count - 1] += "-" + part
            } else {
                words.append(Self.word(part))
            }
        }.joined(separator: " ")
    }

    var command: AgentCommand { AgentCommand(text: "/model \(id)") }

    static func choices(including model: CopilotModel) -> [CopilotModel] {
        let known = [automatic] + catalog
        return known.contains(model) ? known : known + [model]
    }

    private static func word(_ part: Substring) -> String {
        ["gpt", "mai"].contains(part) ? part.uppercased() : part.prefix(1).uppercased() + part.dropFirst()
    }
}

struct CopilotModelState: Codable, Hashable, Sendable {
    var selected: CopilotModel?
    var running: CopilotModel?

    init(selected: CopilotModel? = nil, running: CopilotModel? = nil) {
        self.selected = selected
        self.running = running
    }

    init(choosing model: CopilotModel) {
        self.init(selected: model, running: model.isAutomatic ? nil : model)
    }

    var shown: CopilotModel { selected ?? running ?? .automatic }

    var title: String {
        guard shown.isAutomatic, let running, !running.isAutomatic else { return shown.title }
        return String(localized: "Auto (\(running.title))", comment: "Copilot model menu label when Copilot picks the model; the argument is the model it picked")
    }
}
