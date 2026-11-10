import Foundation

@MainActor protocol SidebarModel: WorkspaceEditing {
    var folders: [ProjectFolder] { get }
    var projects: [Project] { get }
    var selection: UUID? { get set }
    var workInProgress: [WorkInProgressGroup] { get }
    var workInProgressRows: [WorkInProgressRow] { get }

    subscript(expanded id: UUID) -> Bool { get set }
    func isExpanded(_ id: UUID) -> Bool
    func setExpanded(_ id: UUID, _ expanded: Bool)
    func terminalBlocks(in worktreeID: UUID, matching query: String) -> [SidebarTerminalBlock]
    func terminalSummary(_ id: UUID) -> TerminalSummary?
    func branch(at path: String) -> GitBranch?
    func openTerminal(projectID: UUID, worktreeID: UUID, launch: AgentLaunch)
    func wakeProject(_ id: UUID)
    func canMoveFolder(_ id: UUID, to parentID: UUID?) -> Bool
    func moveFolder(_ id: UUID, to parentID: UUID?)
    func removeFolder(_ id: UUID)
    @discardableResult func moveWorktree(_ worktreeID: UUID, to groupID: UUID?) -> Bool
    func removeWorktreeGroup(_ id: UUID)
    func useAutomaticName(_ terminalID: UUID)
    func remove(_ removal: Removal, branch: BranchRemoval)
}

#if os(macOS)
typealias SidebarStore = WorkspaceStore
#else
typealias SidebarStore = MobileWorkspaceStore
#endif
