import SwiftUI

struct ProjectEditMenu: View {
    @Environment(WorkspacePresentation.self) private var presentation

    let project: Project
    let folders: [ProjectFolder]
    let store: any WorkspaceEditing

    private var isBusy: Bool { store.busyProjects.contains(project.id) }

    var body: some View {
        Group {
            Button("New Worktree…", systemImage: "arrow.triangle.branch") { presentation.sheet = .worktree(project.id, project.name) }
                .disabled(isBusy)
            Button("New Worktree Group…", systemImage: "rectangle.stack.badge.plus") { presentation.sheet = .worktreeGroup(projectID: project.id, worktreeID: nil) }
            Menu("Move To", systemImage: "folder") {
                Button("No Folder") { move(to: nil) }
                    .disabled(project.folderID == nil)
                ForEach(folders.destinations()) { destination in
                    Button(destination.title) { move(to: destination.id) }
                        .disabled(project.folderID == destination.id)
                }
            }
            Button("Rename and Customize…", systemImage: "paintpalette") { presentation.sheet = .rename(project.id, project.name) }
            Button("Refresh Worktrees", systemImage: "arrow.clockwise") { Task { await store.refreshWorktrees(project.id) } }
                .disabled(isBusy)
        }
        .disabled(store.isReadOnly)
    }

    private func move(to folderID: UUID?) {
        store.perform { try await store.moveProject(project.id, to: folderID) }
    }
}
