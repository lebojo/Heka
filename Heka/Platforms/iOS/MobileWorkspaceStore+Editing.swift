import Foundation

extension MobileWorkspaceStore: WorkspaceEditing {
    var isReadOnly: Bool { !isConnected }

    func isBusy(_ removal: Removal) -> Bool {
        removal.projectID.map(busyProjects.contains) ?? false
    }

    func appearance(of id: UUID) -> SidebarAppearance? {
        workspace.folders.first { $0.id == id }?.appearance ?? workspace.projects.first { $0.id == id }?.appearance
    }

    func addFolder(_ name: String, parentID: UUID?, appearance: SidebarAppearance?) async throws {
        let _: Bool = try await call(.addFolder(name: name, parent: parentID, appearance: appearance))
    }

    func rename(_ id: UUID, to name: String, appearance: SidebarAppearance?) async throws {
        let _: Bool = try await call(.rename(id: id, name: name, appearance: appearance))
    }

    func moveProject(_ id: UUID, to folderID: UUID?) async throws {
        let _: Bool = try await call(.moveProject(project: id, folder: folderID))
    }

    func addWorktreeGroup(_ name: String, projectID: UUID, moving worktreeID: UUID?) async throws -> UUID? {
        try await call(.addWorktreeGroup(name: name, project: projectID, worktree: worktreeID))
    }

    func openWorktree(projectID: UUID, branch: String, remote: String?, launch: AgentLaunch) async throws {
        let agent = launch.onNewWorktree ? launch.agent : nil
        let id: UUID = try await busy(projectID) { try await call(.createWorktree(project: projectID, branch: branch, remote: remote, agent: agent)) }
        selection = id
    }

    func availableBranches(projectID: UUID) async -> [BranchSuggestion] {
        (try? await call(.projectBranches(project: projectID))) ?? []
    }

    func fetchRemotes(projectID: UUID) async throws {
        let _: Bool = try await busy(projectID) { try await call(.fetchRemotes(project: projectID)) }
    }

    func refreshWorktrees(_ id: UUID) async {
        do { let _: Bool = try await busy(id) { try await call(.refreshWorktrees(project: id)) } }
        catch { report(error) }
    }

    func deletableBranch(for removal: Removal) async -> String? {
        (try? await call(.deletableBranch(removal: removal)) as String?) ?? nil
    }

    func performRemoval(_ removal: Removal, branch: BranchRemoval) async throws {
        if let projectID = removal.projectID {
            let _: Bool = try await busy(projectID) { try await call(.remove(removal: removal, branch: branch)) }
        } else {
            let _: Bool = try await call(.remove(removal: removal, branch: branch))
        }
        if case .terminal(let id) = removal, selection == id { selection = nil }
    }

    func report(_ error: Error) {
        self.error = error.localizedDescription
    }

    private func call<Value: Decodable & Sendable>(_ request: RemoteRequest) async throws -> Value {
        guard wantsConnection else { throw RemoteError(message: String(localized: "The Mac is disconnected.")) }
        return try await RemoteChannel.call(request, host: host, key: try await requiredPairingKey())
    }
}
