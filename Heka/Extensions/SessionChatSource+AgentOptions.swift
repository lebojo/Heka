extension SessionChatSource {
    var supportsAgentOptions: Bool { self == .claude }

    var models: [AgentModel] { supportsAgentOptions ? AgentModel.allCases : [] }

    var modelPickerCommand: AgentCommand? {
        switch self {
        case .codex, .copilot: AgentCommand(text: "/model")
        case .openCode: AgentCommand(text: "/models")
        case .claude, .terminal: nil
        }
    }

    func efforts(for model: AgentModel) -> [AgentEffort] { supportsAgentOptions ? model.efforts : [] }
}
