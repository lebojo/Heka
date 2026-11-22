#if os(macOS)
import SwiftUI

struct SidebarAddMenu: View {
    @Environment(WorkspaceStore.self) private var store
    @Environment(WorkspacePresentation.self) private var presentation

    var body: some View {
        Menu {
            Button("Add Project…", systemImage: "folder.badge.plus") { store.chooseProjects() }
                .keyboardShortcut(.addProject)
            Button("Import Folder…", systemImage: "square.and.arrow.down") { store.chooseFolder() }
            Divider()
            Button("New Virtual Folder…", systemImage: "folder.badge.plus") { presentation.sheet = .folder(parentID: nil) }
        } label: {
            Image(systemName: "plus").frame(width: IconSize.l, height: IconSize.l)
        }
        .menuStyle(.button)
        .buttonStyle(.borderless)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Add projects or a virtual folder")
        .accessibilityLabel("Add projects or a virtual folder")
        .disabled(!store.canImport)
    }
}
#endif
