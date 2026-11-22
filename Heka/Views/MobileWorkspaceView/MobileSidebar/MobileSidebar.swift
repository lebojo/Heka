import SwiftUI

struct MobileSidebar: View {
    @SceneStorage("sidebarPage") private var page = SidebarPage.projects

    @State private var search = ""
    @State private var filtered = SidebarFilterResult()
    @State private var presentation = WorkspacePresentation()

    @Binding var settingsVisible: Bool

    @Bindable var store: MobileWorkspaceStore

    private var hasNoResults: Bool {
        page == .projects && filtered.groups.isEmpty && filtered.ungrouped.isEmpty
    }

    var body: some View {
        MobileSidebarPage(page: page, result: filtered, query: search)
            .modifier(MobileRemovalConfirmation())
            .environment(store)
            .environment(presentation)
            .environment(\.agentLaunch, store.agentLaunch)
            .sheet(item: $presentation.sheet) { item in
                WorkspaceEditor(store: store, sheet: item, defaultLaunch: store.agentLaunch, agents: store.installedAgents)
            }
            .searchable(text: $search, prompt: Text(page.searchPrompt))
            .onChange(of: SidebarFilterInput(folders: store.workspace.folders, projects: store.workspace.projects, query: page == .projects ? search : ""), initial: true) { _, input in
                filtered = input.filtered()
            }
            .overlay {
                MobileSidebarPlaceholder(settingsVisible: $settingsVisible,
                                         isEmpty: store.workspace.projects.isEmpty && store.workspace.folders.isEmpty,
                                         isConnected: store.isConnected, hasNoResults: hasNoResults, search: search)
            }
            .safeAreaInset(edge: .bottom) {
                MobileConnectionStatus(isConnected: store.isConnected, text: store.statusText)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    SidebarPagePicker(page: $page)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Settings", systemImage: "gearshape") { settingsVisible = true }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("New Virtual Folder…", systemImage: "folder.badge.plus") { presentation.sheet = .folder(parentID: nil) }
                        .disabled(!store.isConnected || page != .projects)
                }
            }
    }
}
