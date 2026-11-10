import SwiftUI

struct MobileProjectRow: View {
    @Environment(MobileWorkspaceStore.self) private var store

    @State private var expanded = true

    let project: Project

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            ForEach(project.worktrees) { worktree in
                MobileWorktreeRow(project: project, worktree: worktree)
            }
        } label: {
            HStack {
                Label {
                    Text(project.name)
                } icon: {
                    Image(systemName: project.appearance.displaySymbol.systemName).foregroundStyle(project.appearance.color)
                }
                Spacer()
                if store.busyProjects.contains(project.id) { ProgressView() }
            }
            .contextMenu { MobileProjectMenu(project: project) }
            .swipeActions(edge: .trailing) { MobileRemovalButton(removal: .project(project.id), placement: .swipe) }
        }
        .selectionDisabled()
    }
}
