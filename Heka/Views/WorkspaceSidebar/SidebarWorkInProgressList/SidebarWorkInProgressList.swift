import SwiftUI

struct SidebarWorkInProgressList: View {
    @Environment(SidebarStore.self) private var store

    let query: String

    private var rows: [WorkInProgressRow] {
        query.isEmpty ? store.workInProgressRows : WorkInProgress.groups(store.workInProgress, matching: query).flatMap(\.rows)
    }

    var body: some View {
        let rows = rows
        List(selection: Bindable(store).listSelection) {
            ForEach(rows) { row in
                SidebarWorkInProgressRow(row: row)
            }
        }
        .listStyle(.sidebar)
        .overlay {
            if rows.isEmpty {
                Text(query.isEmpty ? "No agent is working" : "No Results")
                    .font(Font.callout).foregroundStyle(Color.textSecondary)
            }
        }
    }
}
