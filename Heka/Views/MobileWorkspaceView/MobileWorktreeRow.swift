import SwiftUI

struct MobileWorktreeRow: View {
    @Environment(MobileWorkspaceStore.self) private var store

    @State private var expanded = true

    let project: Project
    let worktree: Worktree

    private var removal: Removal { .worktree(projectID: project.id, worktreeID: worktree.id, name: worktree.displayName) }

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            ForEach(worktree.terminals) { terminal in
                NavigationLink(value: MobileSidebar.Selection.terminal(terminal.id)) {
                    Label { Text(terminal.name) } icon: { TerminalIcon(agent: store.terminalAgents[terminal.id]) }
                }
                .selectionDisabled(false)
                .swipeActions(edge: .trailing) { MobileRemovalButton(removal: .terminal(terminal.id), placement: .swipe) }
            }
        } label: {
            Label(worktree.displayName, systemImage: "arrow.triangle.branch").foregroundStyle(Palette.textSecondary)
                .swipeActions(edge: .leading) {
                    Button("New Terminal", systemImage: "terminal") {
                        Task { await store.newTerminal(projectID: project.id, worktreeID: worktree.id) }
                    }
                    .tint(Palette.accent)
                    .disabled(store.isReadOnly)
                }
                .swipeActions(edge: .trailing) {
                    if !worktree.isPrimary { MobileRemovalButton(removal: removal, placement: .swipe) }
                }
                .contextMenu {
                    Button("New Terminal", systemImage: "terminal") {
                        Task { await store.newTerminal(projectID: project.id, worktreeID: worktree.id) }
                    }
                    .disabled(store.isReadOnly)
                    if !worktree.isPrimary {
                        Divider()
                        MobileRemovalButton(removal: removal, placement: .menu)
                    }
                }
        }
        .selectionDisabled()
    }
}
