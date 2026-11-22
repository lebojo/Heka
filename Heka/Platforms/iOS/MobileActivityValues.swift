import Foundation

@MainActor final class MobileActivityValues {
    private var activity = SidebarActivity()
    private var terminals: [UUID: MobileObservedValue<TerminalSummary>] = [:]
    private var branches: [String: MobileObservedValue<GitBranch>] = [:]

    func terminalSummary(_ id: UUID) -> TerminalSummary? {
        Self.observed(id, in: &terminals, current: activity.terminals[id])
    }

    func branch(at path: String) -> GitBranch? {
        Self.observed(path, in: &branches, current: activity.branches[path])
    }

    func update(_ activity: SidebarActivity) {
        self.activity = activity
        for (id, summary) in terminals { summary.update(activity.terminals[id]) }
        for (path, branch) in branches { branch.update(activity.branches[path]) }
    }

    func keep(_ workspace: Workspace) {
        let worktrees = workspace.projects.flatMap(\.worktrees)
        let ids = Set(worktrees.flatMap(\.terminals).map(\.id))
        let paths = Set(worktrees.map(\.path))
        terminals = terminals.filter { ids.contains($0.key) }
        branches = branches.filter { paths.contains($0.key) }
    }

    private static func observed<Key: Hashable, Value>(_ key: Key, in values: inout [Key: MobileObservedValue<Value>], current: Value?) -> Value? {
        if let value = values[key] { return value.value }
        let value = MobileObservedValue(current)
        values[key] = value
        return value.value
    }
}
