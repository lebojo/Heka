import SwiftUI

struct SidebarWorktreeGroupRow: View {
    @Environment(SidebarStore.self) private var store
    @Environment(WorkspacePresentation.self) private var presentation

    @State private var isDropTargeted = false

    let project: Project
    let content: SidebarProjectContent.Group
    let query: String

    private var group: WorktreeGroup { content.group }
    private var isExpanded: Binding<Bool> {
        query.isEmpty ? Bindable(store)[expanded: group.id] : .constant(true)
    }

    var body: some View {
        DisclosureGroup(isExpanded: isExpanded) {
            ForEach(content.worktrees) { worktree in
                SidebarWorktreeRow(projectID: project.id, worktreeGroups: project.worktreeGroups, worktree: worktree, query: query, showAll: content.showsAll)
            }
            #if os(macOS)
            .onMove(perform: store.isReadOnly ? nil : { store.reorderWorktrees(in: project.id, content.worktrees.map(\.id), from: $0, to: $1) })
            #endif
            if content.total == 0 {
                Text("Drag a worktree here").font(Font.caption).foregroundStyle(Color.textSecondary)
            }
        } label: {
            HStack(spacing: Spacing.s) {
                Image(systemName: "rectangle.stack").foregroundStyle(Color.textSecondary)
                Text(group.name).lineLimit(1)
                Spacer(minLength: Spacing.xxs)
                Text("\(content.total)")
                    .font(Font.caption).monospacedDigit().foregroundStyle(Color.textSecondary)
            }
            .contentShape(Rectangle())
            .background(isDropTargeted ? Color.dropTargetFill : .clear, in: RoundedRectangle(cornerRadius: Radius.s))
            .help(group.name)
            #if os(macOS)
            .dropDestination(for: String.self) { values, _ in
                guard let value = values.first, let id = UUID(uuidString: value) else { return false }
                return store.moveWorktree(id, to: group.id)
            } isTargeted: { isDropTargeted = $0 }
            #endif
            .contextMenu {
                Button("Rename…", systemImage: "pencil") { presentation.sheet = .rename(group.id, group.name) }
                Divider()
                Button("Dissolve Group", systemImage: "rectangle.stack.badge.minus") { store.removeWorktreeGroup(group.id) }
            }
        }
    }
}
