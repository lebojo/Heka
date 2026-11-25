#if os(macOS)
import SwiftUI

struct SidebarPageContent: View {
    @Environment(WorkspaceStore.self) private var store

    @State private var isDropTargeted = false

    let page: SidebarPage
    let result: SidebarFilterResult
    let query: String

    var body: some View {
        switch page {
        case .projects:
            SidebarProjectList(result: result, query: query)
                .overlay { SidebarEmptyState(result: result, query: query) }
                .overlay { if isDropTargeted { DropTargetHighlight() } }
                .dropDestination(for: URL.self) { urls, _ in
                    store.acceptDroppedFolders(urls)
                } isTargeted: { isDropTargeted = $0 && store.canImport }
        case .workInProgress:
            SidebarWorkInProgressList(query: query)
        }
    }
}
#endif
