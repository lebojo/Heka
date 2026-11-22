#if os(macOS)
import SwiftUI

struct SidebarEmptyState: View {
    @Environment(WorkspaceStore.self) private var store

    let result: SidebarFilterResult
    let query: String

    private var isEmpty: Bool {
        store.projects.isEmpty && store.folders.isEmpty && store.orphanWorktrees.isEmpty
    }
    private var hasNoResults: Bool {
        !query.isEmpty && result.groups.isEmpty && result.ungrouped.isEmpty
            && !store.orphanWorktrees.contains { $0.folderName.localizedStandardContains(query) || ($0.branch?.localizedStandardContains(query) ?? false) }
    }

    var body: some View {
        if isEmpty {
            VStack(spacing: Spacing.m) {
                Image(systemName: "folder.badge.plus").font(Font.emptyStateSymbol)
                Text("All your projects in one place").font(Font.m.weight(.medium))
                Text("Add a project to get started.").font(Font.s).foregroundStyle(Color.textSecondary)
                Button("Add Project…") { store.chooseProjects() }
                    .controlSize(.small).padding(.top, Spacing.xs)
                    .disabled(!store.canImport)
            }
            .foregroundStyle(Color.textSecondary)
            .padding()
        } else if hasNoResults {
            Text("No Results").font(Font.callout).foregroundStyle(Color.textSecondary)
        }
    }
}
#endif
