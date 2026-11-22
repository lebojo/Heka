import SwiftUI

struct GitChangeList: View {
    @State private var collapsed: Set<String> = []
    @State private var visibleRows: [GitChangeTreeRow] = []

    let root: String
    let scope: GitChangeScope
    let outline: GitChangeOutline
    let omitted: Int
    let source: any InspectorSource

    var body: some View {
        LazyVStack(alignment: .leading, spacing: Spacing.xs) {
            GitChangeSectionHeader(title: scope.title(count: outline.count + omitted), action: outline.isEmpty ? nil : scope.bulkAction,
                                   root: root, source: source)
            if outline.isEmpty {
                Label { Text(scope.emptyTitle) } icon: { Image(systemName: "checkmark.circle") }
                    .foregroundStyle(Color.textSecondary).font(.callout)
            }
            ForEach(visibleRows) { row in
                GitChangeOutlineRow(collapsed: $collapsed, row: row, root: root, scope: scope, source: source)
            }
            if omitted > 0 {
                InspectorNotice(title: "Truncated List", message: "\(omitted) more changes aren’t listed.", symbol: "ellipsis.circle")
            }
        }
        .onChange(of: outline, updateVisibleRows)
        .onChange(of: collapsed, initial: true, updateVisibleRows)
    }

    private func updateVisibleRows() {
        visibleRows = outline.rows(collapsing: collapsed)
    }
}
