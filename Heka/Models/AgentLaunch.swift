import Foundation

struct AgentLaunch: Codable, Hashable, Sendable {
    enum Trigger: Sendable {
        case newTerminal, newWorktree
    }

    var agent: ConversationAgent = .claude
    var onNewWorktree = false
    var onNewTerminal = false
    var skipsPermissions = false

    var previewCommand: String { agent.launchCommand(skippingPermissions: skipsPermissions).joined(separator: " ") }

    func command(prompt: String) -> [String] {
        agent.promptCommand(prompt, skippingPermissions: skipsPermissions)
    }

    func launches(on trigger: Trigger) -> Bool {
        switch trigger {
        case .newTerminal: onNewTerminal
        case .newWorktree: onNewWorktree
        }
    }

    func command(on trigger: Trigger) -> [String] {
        launches(on: trigger) ? agent.launchCommand(skippingPermissions: skipsPermissions) : []
    }
}

extension AgentLaunch {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let agent = try? container.decodeIfPresent(ConversationAgent.self, forKey: .agent) { self.agent = agent }
        if let onNewWorktree = try? container.decodeIfPresent(Bool.self, forKey: .onNewWorktree) { self.onNewWorktree = onNewWorktree }
        if let onNewTerminal = try? container.decodeIfPresent(Bool.self, forKey: .onNewTerminal) { self.onNewTerminal = onNewTerminal }
        if let skipsPermissions = try? container.decodeIfPresent(Bool.self, forKey: .skipsPermissions) { self.skipsPermissions = skipsPermissions }
    }
}
