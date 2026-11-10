import SwiftUI

struct SidebarOrphanSection: View {
    @Environment(WorkspaceStore.self) private var store

    let query: String

    private var orphans: [DiscoveredWorktree] {
        store.orphanWorktrees.filter { query.isEmpty || $0.folderName.localizedStandardContains(query) || ($0.branch?.localizedStandardContains(query) ?? false) }
    }

    var body: some View {
        let orphans = orphans
        if !orphans.isEmpty {
            Section("Orphans") {
                ForEach(orphans) { worktree in
                    SidebarOrphanRow(worktree: worktree)
                }
            }
        }
    }
}
