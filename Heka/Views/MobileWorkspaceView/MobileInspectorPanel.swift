import SwiftUI

struct MobileInspectorPanel: View {
    let store: MobileWorkspaceStore

    var body: some View {
        if let context = store.context {
            WorkspaceInspector(context: context,
                               source: MobileInspectorSource(hostID: store.selectedHostID, worktree: context.worktree.id, store: store))
        } else {
            ContentUnavailableView("No Terminal Selected", systemImage: "sidebar.right")
        }
    }
}
