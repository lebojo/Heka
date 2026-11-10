import Foundation

extension MobileWorkspaceStore: SidebarModel {
    var folders: [ProjectFolder] { workspace.folders }
    var projects: [Project] { workspace.projects }
    var workInProgress: [WorkInProgressGroup] {
        WorkInProgress.groups(in: workspace.projects, statuses: activity.statuses, agents: activity.agents)
    }
    var workInProgressRows: [WorkInProgressRow] { workInProgress.flatMap(\.rows) }

    subscript(expanded id: UUID) -> Bool {
        get { isExpanded(id) }
        set { setExpanded(id, newValue) }
    }

    func terminalBlocks(in worktreeID: UUID, matching query: String) -> [SidebarTerminalBlock] {
        guard let worktree = workspace.projects.lazy.flatMap(\.worktrees).first(where: { $0.id == worktreeID }) else { return [] }
        let terminals = query.isEmpty ? worktree.terminals : worktree.terminals.filter { $0.name.localizedStandardContains(query) }
        return worktree.terminalBlocks(showing: terminals)
    }

    func terminalSummary(_ id: UUID) -> TerminalSummary? { activity.terminals[id] }

    func branch(at path: String) -> GitBranch? { activity.branches[path] }

    func openTerminal(projectID: UUID, worktreeID: UUID, launch: AgentLaunch) {
        Task { await newTerminal(projectID: projectID, worktreeID: worktreeID) }
    }

    func wakeProject(_ id: UUID) {
        guard let project = workspace.projects.first(where: { $0.id == id }), project.worktrees.allSatisfy({ $0.terminals.isEmpty }),
              let worktree = project.worktrees.first(where: \.isPrimary) ?? project.worktrees.first else { return }
        openTerminal(projectID: id, worktreeID: worktree.id, launch: agentLaunch)
    }

    func canMoveFolder(_ id: UUID, to parentID: UUID?) -> Bool { workspace.folders.canMove(id, to: parentID) }

    func moveFolder(_ id: UUID, to parentID: UUID?) { send(.moveFolder(folder: id, parent: parentID)) }

    func removeFolder(_ id: UUID) { send(.removeFolder(folder: id)) }

    @discardableResult func moveWorktree(_ worktreeID: UUID, to groupID: UUID?) -> Bool {
        send(.moveWorktree(worktree: worktreeID, group: groupID))
        return true
    }

    func removeWorktreeGroup(_ id: UUID) { send(.removeWorktreeGroup(group: id)) }

    func useAutomaticName(_ terminalID: UUID) { send(.useAutomaticName(terminal: terminalID)) }

    func remove(_ removal: Removal, branch: BranchRemoval) {
        perform { try await self.performRemoval(removal, branch: branch) }
    }

    private func send(_ request: RemoteRequest) {
        perform { let _: Bool = try await self.call(request) }
    }
}
