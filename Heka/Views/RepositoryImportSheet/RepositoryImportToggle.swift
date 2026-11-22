#if os(macOS)
import SwiftUI

struct RepositoryImportToggle: View {
    @Binding var selection: Set<String>

    let item: RepositoryImportItem

    private var appearance: SidebarAppearance {
        SidebarAppearance(kind: item.children == nil ? .project : .folder)
    }

    var body: some View {
        Toggle(sources: item.repositoryPaths.map { $selection[contains: $0] }, isOn: \.self) {
            Label {
                Text(item.name).lineLimit(1).truncationMode(.middle)
            } icon: {
                Image(systemName: appearance.displaySymbol.systemName).foregroundStyle(appearance.color)
            }
        }
        .toggleStyle(.checkbox)
        .help(item.path)
    }
}
#endif
