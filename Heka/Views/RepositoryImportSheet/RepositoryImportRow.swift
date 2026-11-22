import SwiftUI

struct RepositoryImportRow: View {
    @State private var expanded = true

    @Binding var selection: Set<String>

    let item: RepositoryImportItem

    var body: some View {
        if let children = item.children {
            DisclosureGroup(isExpanded: $expanded) {
                ForEach(children) { child in
                    RepositoryImportRow(selection: $selection, item: child)
                }
            } label: {
                RepositoryImportToggle(selection: $selection, item: item)
            }
        } else {
            RepositoryImportToggle(selection: $selection, item: item)
        }
    }
}
