import AppKit
import SwiftUI

struct SidebarProjectMenu: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(WorkspaceStore.self) private var store

    let project: Project

    var body: some View {
        Button("New Terminal", systemImage: "terminal") {
            if let main = project.worktrees.first(where: \.isPrimary) { store.openTerminal(projectID: project.id, worktreeID: main.id, launch: settings.agentLaunch) }
        }
        ProjectEditMenu(project: project, folders: store.folders, store: store)
        Button("Show in Finder", systemImage: "folder") { NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: project.path) }
        Divider()
        RemovalButton(removal: .project(project.id), placement: .menu)
    }
}
