import SwiftUI

struct SidebarProjectRow: View {
    @Environment(\.agentLaunch) private var agentLaunch
    @Environment(SidebarStore.self) private var store

    @State private var content = SidebarProjectContent()

    let project: Project
    let query: String
    let showAll: Bool

    private var isExpanded: Binding<Bool> {
        query.isEmpty ? Bindable(store)[expanded: project.id] : .constant(true)
    }

    var body: some View {
        DisclosureGroup(isExpanded: isExpanded) {
            ForEach(content.primary) { worktree in
                SidebarTerminalList(worktreeID: worktree.id, query: content.showsEverything ? "" : query)
                if worktree.terminals.isEmpty {
                    Button("Open Terminal") { store.openTerminal(projectID: project.id, worktreeID: worktree.id, launch: agentLaunch) }
                        .buttonStyle(.plain).font(Font.caption).foregroundStyle(Color.textSecondary)
                }
            }
            ForEach(content.groups) { group in
                SidebarWorktreeGroupRow(project: project, content: group, query: query)
            }
            #if os(macOS)
            .onMove(perform: store.isReadOnly ? nil : { store.reorderWorktreeGroups(in: project.id, content.groups.map(\.id), from: $0, to: $1) })
            #endif
            ForEach(content.ungrouped) { worktree in
                SidebarWorktreeRow(projectID: project.id, worktreeGroups: project.worktreeGroups, worktree: worktree, query: query, showAll: content.showsEverything)
            }
            #if os(macOS)
            .onMove(perform: store.isReadOnly ? nil : { store.reorderWorktrees(in: project.id, content.ungrouped.map(\.id), from: $0, to: $1) })
            #endif
        } label: {
            SidebarProjectLabel(project: project)
        }
        .onChange(of: SidebarProjectInput(project: project, query: query, showAll: showAll), initial: true) { _, input in
            content = input.content()
        }
    }
}
