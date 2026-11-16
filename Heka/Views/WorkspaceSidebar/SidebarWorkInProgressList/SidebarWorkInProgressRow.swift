import SwiftUI

struct SidebarWorkInProgressRow: View {
    let row: WorkInProgressRow

    var body: some View {
        VStack(spacing: 0) {
            switch row {
            case .status(let status, let count):
                SidebarStatusHeader(status: status, count: count)
            case .terminal(let item, let startsProject):
                if startsProject {
                    Divider().padding(.horizontal, Spacing.xs).padding(.bottom, Spacing.xxs).accessibilityHidden(true)
                }
                SidebarWorkInProgressItemRow(item: item)
            }
        }
        .selectionDisabled()
    }
}
