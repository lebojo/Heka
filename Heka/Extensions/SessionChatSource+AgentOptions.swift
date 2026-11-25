extension SessionChatSource {
    var supportsAgentOptions: Bool { self == .claude || self == .copilot }

    var models: [AgentModel] { self == .claude ? AgentModel.allCases : [] }

    var modelPickerCommand: AgentCommand? {
        switch self {
        case .codex: AgentCommand(text: "/model")
        case .openCode: AgentCommand(text: "/models")
        case .claude, .copilot, .terminal: nil
        }
    }

    func efforts(for model: AgentModel) -> [AgentEffort] { self == .claude ? model.efforts : [] }
}
