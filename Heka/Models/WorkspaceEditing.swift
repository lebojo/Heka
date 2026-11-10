import Foundation

@MainActor protocol WorkspaceEditing: AnyObject {
    var busyProjects: Set<UUID> { get }
    var isReadOnly: Bool { get }

    func isBusy(_ removal: Removal) -> Bool
    func appearance(of id: UUID) -> SidebarAppearance?
    func addFolder(_ name: String, parentID: UUID?, appearance: SidebarAppearance?) async throws
    func rename(_ id: UUID, to name: String, appearance: SidebarAppearance?) async throws
    func moveProject(_ id: UUID, to folderID: UUID?) async throws
    func addWorktreeGroup(_ name: String, projectID: UUID, moving worktreeID: UUID?) async throws -> UUID?
    func openWorktree(projectID: UUID, branch: String, remote: String?, launch: AgentLaunch) async throws
    func availableBranches(projectID: UUID) async -> [BranchSuggestion]
    func fetchRemotes(projectID: UUID) async throws
    func refreshWorktrees(_ id: UUID) async
    func deletableBranch(for removal: Removal) async -> String?
    func performRemoval(_ removal: Removal, branch: BranchRemoval) async throws
    func report(_ error: Error)
}

extension WorkspaceEditing {
    func perform(_ operation: @escaping @MainActor () async throws -> Void) {
        Task { @MainActor in
            do { try await operation() } catch { report(error) }
        }
    }

    func deletableBranchBeforeDeadline(for removal: Removal) async -> String? {
        guard case .worktree = removal else { return nil }
        let (lookups, continuation) = AsyncStream.makeStream(of: String?.self)
        let lookup = Task { continuation.yield(await deletableBranch(for: removal)) }
        let deadline = Task {
            try? await Task.sleep(for: Removal.branchLookupDeadline)
            continuation.yield(nil)
        }
        var iterator = lookups.makeAsyncIterator()
        let first = await iterator.next()
        lookup.cancel()
        deadline.cancel()
        continuation.finish()
        return first ?? nil
    }
}
