import SwiftUI

struct SidebarWorktreeRow: View {
    @Environment(\.agentLaunch) private var agentLaunch
    @Environment(SidebarStore.self) private var store

    #if os(iOS)
    @State private var isInserted = false
    #endif

    let projectID: UUID
    let worktreeGroups: [WorktreeGroup]
    let worktree: Worktree
    let query: String
    let showAll: Bool

    private var terminalQuery: String {
        showAll || matches(worktree.displayName) ? "" : query
    }
    private var isExpanded: Binding<Bool> {
        #if os(iOS)
        guard isInserted else { return .constant(false) }
        #endif
        return query.isEmpty ? Bindable(store)[expanded: worktree.id] : .constant(true)
    }

    var body: some View {
        DisclosureGroup(isExpanded: isExpanded) {
            SidebarTerminalList(worktreeID: worktree.id, query: terminalQuery)
            if worktree.terminals.isEmpty {
                Button("Open Terminal") { store.openTerminal(projectID: projectID, worktreeID: worktree.id, launch: agentLaunch) }
                    .buttonStyle(.plain).font(Font.caption).foregroundStyle(Color.textSecondary)
            }
        } label: {
            SidebarWorktreeLabel(projectID: projectID, worktreeGroups: worktreeGroups, worktreeID: worktree.id, name: worktree.name,
                                 displayName: worktree.displayName, path: worktree.path, groupID: worktree.groupID)
        }
        #if os(iOS)
        .task { isInserted = true }
        #endif
    }

    private func matches(_ value: String) -> Bool { query.isEmpty || value.localizedStandardContains(query) }
}
