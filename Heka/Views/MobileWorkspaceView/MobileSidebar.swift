import SwiftUI

struct MobileSidebar: View {
    @State private var search = ""
    @State private var filtered = SidebarFilterResult()
    @State private var presentation = WorkspacePresentation()

    @Bindable var store: MobileWorkspaceStore

    let showSettings: () -> Void

    var body: some View {
        SidebarProjectList(result: filtered, query: search)
            .modifier(MobileRemovalConfirmation())
            .environment(store)
            .environment(presentation)
            .environment(\.agentLaunch, store.agentLaunch)
        .sheet(item: $presentation.sheet) { item in
            WorkspaceEditor(store: store, sheet: item, defaultLaunch: store.agentLaunch, agents: store.installedAgents)
        }
        .searchable(text: $search, prompt: "Filter projects and terminals")
        .onChange(of: SidebarFilterInput(folders: store.workspace.folders, projects: store.workspace.projects, query: search), initial: true) { _, input in
            filtered = input.filtered()
        }
        .overlay {
            if store.workspace.projects.isEmpty {
                ContentUnavailableView {
                    Label(store.isConnected ? "No Projects" : "Your Mac, Within Reach", systemImage: "laptopcomputer.and.iphone")
                } description: {
                    Text(store.isConnected ? "Add a project in Heka on the Mac." : "Connect to the local network to continue a session.")
                } actions: {
                    Button("Connect", action: showSettings).buttonStyle(.borderedProminent)
                }
            } else if filtered.groups.isEmpty && filtered.ungrouped.isEmpty {
                ContentUnavailableView.search(text: search)
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Image(systemName: store.isConnected ? "network" : "network.slash")
                Text(store.statusText).lineLimit(2)
            }.font(Typography.caption).padding(Spacing.l).frame(maxWidth: .infinity, alignment: .leading).background(Palette.bar)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Settings", systemImage: "gearshape", action: showSettings)
            }
            ToolbarItem(placement: .primaryAction) {
                Button("New Virtual Folder…", systemImage: "folder.badge.plus") { presentation.sheet = .folder(parentID: nil) }
                    .disabled(!store.isConnected)
            }
        }
    }
}
