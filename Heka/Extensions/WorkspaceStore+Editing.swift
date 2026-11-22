import Foundation

extension WorkspaceStore: WorkspaceEditing {
    func addFolder(_ name: String, parentID: UUID?, appearance: SidebarAppearance?) async throws {
        let id = addFolder(name, parentID: parentID)
        if let appearance { setAppearance(appearance, for: id) }
    }

    func rename(_ id: UUID, to name: String, appearance: SidebarAppearance?) async throws {
        if let project = projects.first(where: { $0.worktreeGroups.contains { $0.id == id } }) {
            try requireAvailableGroupName(name, in: project.id, renaming: id)
        }
        rename(id, to: name)
        if let appearance { setAppearance(appearance, for: id) }
    }

    func openWorktree(projectID: UUID, branch: String, remote: String?, launch: AgentLaunch) async throws {
        _ = try await createWorktree(projectID: projectID, branch: branch, remote: remote, command: launch.command(on: .newWorktree))
    }

    func report(_ error: Error) {
        errorMessage = error.localizedDescription
    }
}
