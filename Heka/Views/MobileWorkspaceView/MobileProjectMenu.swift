import SwiftUI

struct MobileProjectMenu: View {
    @Environment(MobileWorkspaceStore.self) private var store

    let project: Project

    var body: some View {
        Button("New Terminal", systemImage: "terminal") {
            if let main = project.worktrees.first(where: \.isPrimary) {
                Task { await store.newTerminal(projectID: project.id, worktreeID: main.id) }
            }
        }
        .disabled(store.isReadOnly)
        ProjectEditMenu(project: project, folders: store.workspace.folders, store: store)
        Divider()
        MobileRemovalButton(removal: .project(project.id), placement: .menu)
    }
}
