import Foundation

struct WorkInProgressItem: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let agent: ConversationAgent?
    let projectID: UUID
    let projectName: String
    let worktreeName: String

    var location: String { "\(projectName) · \(worktreeName)" }

    func matches(_ query: String) -> Bool {
        query.isEmpty || [name, projectName, worktreeName].contains { $0.localizedStandardContains(query) }
    }
}

struct WorkInProgressGroup: Identifiable, Equatable, Sendable {
    let status: AgentStatus
    let items: [WorkInProgressItem]

    var id: AgentStatus { status }
    var rows: [WorkInProgressRow] {
        [.status(status, count: items.count)] + items.indices.map { index in
            .terminal(items[index], startsProject: index > 0 && items[index - 1].projectID != items[index].projectID)
        }
    }

    func matching(_ query: String) -> WorkInProgressGroup? {
        let matches = items.filter { $0.matches(query) }
        return matches.isEmpty ? nil : WorkInProgressGroup(status: status, items: matches)
    }
}

enum WorkInProgressRow: Identifiable, Equatable, Sendable {
    case status(AgentStatus, count: Int)
    case terminal(WorkInProgressItem, startsProject: Bool)

    enum ID: Hashable, Sendable {
        case status(AgentStatus)
        case terminal(UUID)
    }

    var id: ID {
        switch self {
        case .status(let status, _): .status(status)
        case .terminal(let item, _): .terminal(item.id)
        }
    }
}

enum WorkInProgress {
    static func groups(in projects: [Project], statuses: [UUID: AgentStatus], agents: [UUID: ConversationAgent]) -> [WorkInProgressGroup] {
        guard !statuses.isEmpty else { return [] }
        var items: [AgentStatus: [WorkInProgressItem]] = [:]
        for project in projects {
            for worktree in project.worktrees {
                for terminal in worktree.terminals {
                    guard let status = statuses[terminal.id] else { continue }
                    items[status, default: []].append(WorkInProgressItem(id: terminal.id, name: terminal.name, agent: agents[terminal.id], projectID: project.id,
                                                                         projectName: project.name, worktreeName: worktree.displayName))
                }
            }
        }
        return AgentStatus.attentionOrder.compactMap { status in
            items[status].map { WorkInProgressGroup(status: status, items: $0) }
        }
    }

    static func listsSameTerminals(_ old: [Project], _ new: [Project]) -> Bool {
        old.elementsEqual(new) { old, new in
            old.id == new.id && old.name == new.name && old.worktrees.elementsEqual(new.worktrees) { old, new in
                old.isPrimary == new.isPrimary && old.name == new.name && old.terminals.elementsEqual(new.terminals) { $0.id == $1.id && $0.name == $1.name }
            }
        }
    }

    static func groups(_ groups: [WorkInProgressGroup], matching query: String) -> [WorkInProgressGroup] {
        query.isEmpty ? groups : groups.compactMap { $0.matching(query) }
    }
}
