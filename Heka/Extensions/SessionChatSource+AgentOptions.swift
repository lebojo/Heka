extension SessionChatSource {
    var supportsAgentOptions: Bool { self == .claude }

    var models: [AgentModel] { supportsAgentOptions ? AgentModel.allCases : [] }

    func efforts(for model: AgentModel) -> [AgentEffort] { supportsAgentOptions ? model.efforts : [] }
}
