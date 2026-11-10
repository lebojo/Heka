import Foundation

struct TerminalSummary: Codable, Equatable, Sendable {
    var agent: ConversationAgent?
    var status: AgentStatus?
    var hasExited = false
    var divergentBranch: GitBranch?
    var subagents: [Subagent] = []
}

struct SidebarActivity: Codable, Equatable, Sendable {
    var terminals: [UUID: TerminalSummary] = [:]
    var branches: [String: GitBranch] = [:]

    var statuses: [UUID: AgentStatus] { terminals.compactMapValues(\.status) }
    var agents: [UUID: ConversationAgent] { terminals.compactMapValues(\.agent) }
}
