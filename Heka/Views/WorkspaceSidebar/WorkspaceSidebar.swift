import SwiftUI

struct WorkspaceSidebar: View {
    @SceneStorage("sidebarPage") private var page = SidebarPage.projects

    @Environment(WorkspaceStore.self) private var store

    @State private var search = ""
    @State private var filtered = SidebarFilterResult()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(page.title).font(Font.headline)
                Spacer()
                if page == .projects { SidebarAddMenu() }
            }
            .frame(minHeight: IconSize.l)
            .padding(.horizontal, Spacing.l).padding(.top, Spacing.m)

            SearchField(text: $search, prompt: page.searchPrompt)
                .padding(.horizontal, Spacing.l).padding(.top, Spacing.m).padding(.bottom, Spacing.l)

            SidebarPageContent(page: page, result: filtered, query: search)
                .safeAreaInset(edge: .bottom, spacing: 0) { UsageBar() }

            SidebarFooter()
        }
        .toolbar {
            ToolbarItem {
                SidebarPagePicker(page: $page)
            }

            ToolbarItem {
                FloatingTerminalButton()
            }
        }
        .onChange(of: SidebarFilterInput(folders: store.folders, projects: store.projects, query: page == .projects ? search : ""), initial: true) { _, input in
            filtered = input.filtered()
        }
    }
}
