import SwiftUI

struct MobileFolderRow: View {
    @Environment(MobileWorkspaceStore.self) private var store
    @Environment(WorkspacePresentation.self) private var presentation

    let group: SidebarFilterResult.Group

    var body: some View {
        DisclosureGroup {
            ForEach(group.subgroups) { subgroup in MobileFolderRow(group: subgroup) }
            ForEach(group.projects) { project in MobileProjectRow(project: project) }
        } label: {
            Label {
                Text(group.folder.name)
            } icon: {
                Image(systemName: group.folder.appearance.displaySymbol.systemName).foregroundStyle(group.folder.appearance.color)
            }
            .contextMenu {
                Group {
                    Button("New Subfolder…", systemImage: "folder.badge.plus") { presentation.sheet = .folder(parentID: group.folder.id) }
                    Button("Rename and Customize…", systemImage: "paintpalette") { presentation.sheet = .rename(group.folder.id, group.folder.name) }
                }
                .disabled(store.isReadOnly)
            }
        }
        .selectionDisabled()
    }
}
