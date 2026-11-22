#if os(macOS)
import SwiftUI

struct SidebarPageContent: View {
    let page: SidebarPage
    let result: SidebarFilterResult
    let query: String

    var body: some View {
        switch page {
        case .projects:
            SidebarProjectList(result: result, query: query)
                .overlay { SidebarEmptyState(result: result, query: query) }
        case .workInProgress:
            SidebarWorkInProgressList(query: query)
        }
    }
}
#endif
