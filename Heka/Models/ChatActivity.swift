import Foundation

enum ChatActivity: Equatable, Sendable {
    case idle, working

    static let agentStartGrace: Duration = .seconds(3)

    init(status: AgentStatus?, isSending: Bool, isEnabled: Bool) {
        guard isEnabled else { self = .idle; return }
        self = isSending || status == .working ? .working : .idle
    }

    init(subagent status: SubagentStatus) {
        self = status == .working ? .working : .idle
    }

    var showsIndicator: Bool { self == .working }

    func allowsInterrupt(from source: SessionChatSource, status: AgentStatus?) -> Bool {
        source == .terminal || status == nil || self == .working || status == .waitingForInput
    }
}
