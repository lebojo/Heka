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

    func openTerminal(projectID: UUID, worktreeID: UUID, launch: AgentLaunch) {
        Task { await newTerminal(projectID: projectID, worktreeID: worktreeID) }
    }

    func wakeProject(_ id: UUID) {
        guard let project = workspace.projects.first(where: { $0.id == id }) else {
            error = String(localized: "Project not found.")
            return
        }
        if let open = project.openTerminal(preferring: selection, avoiding: []) {
            setExpanded(id, true)
            setExpanded(open.worktreeID, true)
            selection = open.terminalID
            return
        }
        guard let worktree = project.worktreeForNewTerminal(avoiding: []) else {
            error = String(localized: "This project has no worktree to open a terminal in.")
            return
        }
        Task { await newTerminal(projectID: id, worktreeID: worktree.id, opensShell: true) }
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
