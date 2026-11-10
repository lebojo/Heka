import SwiftUI

struct SidebarFolderRow: View {
    @Environment(SidebarStore.self) private var store
    @Environment(WorkspacePresentation.self) private var presentation

    @State private var isDropTargeted = false

    let group: SidebarFilterResult.Group
    let query: String

    private var folder: ProjectFolder { group.folder }

    private var expanded: Binding<Bool> {
        query.isEmpty ? Bindable(store)[expanded: folder.id] : .constant(true)
    }

    var body: some View {
        DisclosureGroup(isExpanded: expanded) {
            ForEach(group.subgroups) { subgroup in
                SidebarFolderRow(group: subgroup, query: query)
            }
            #if os(macOS)
            .onMove(perform: store.isReadOnly ? nil : { store.reorderFolders(group.subgroups.map(\.id), from: $0, to: $1) })
            #endif
            ForEach(group.projects) { project in
                SidebarProjectRow(project: project, query: query, showAll: group.showsAll)
            }
            #if os(macOS)
            .onMove(perform: store.isReadOnly ? nil : { store.reorderProjects(group.projects.map(\.id), from: $0, to: $1) })
            #endif
            #if os(macOS)
            if group.isEmpty {
                Button("Add Project…") { store.chooseProjects(in: folder.id) }
                    .font(Typography.m).foregroundStyle(Palette.textSecondary)
                    .buttonStyle(.plain).padding(.vertical, Spacing.xs)
            }
            #endif
        } label: {
            HStack {
                Label {
                    Text(folder.name)
                } icon: {
                    Image(systemName: folder.appearance.displaySymbol.systemName)
                        .foregroundStyle(folder.appearance.color)
                }
                .fontWeight(.medium).lineLimit(1)

                Spacer(minLength: Spacing.xs)

                Text("\(group.total)")
                    .font(Typography.caption).monospacedDigit().foregroundStyle(Palette.textSecondary)
            }
            .contentShape(Rectangle())
            .background(isDropTargeted ? Palette.dropTargetFill : .clear, in: RoundedRectangle(cornerRadius: Radius.s))
            .help(folder.name)
            #if os(macOS)
            .draggable(folder.id.uuidString)
            .dropDestination(for: String.self) { values, _ in
                guard let value = values.first, let id = UUID(uuidString: value) else { return false }
                return store.drop(id, into: folder.id)
            } isTargeted: { isDropTargeted = $0 }
            #endif
            .contextMenu {
                #if os(macOS)
                Button("Add Projects…", systemImage: "plus") { store.chooseProjects(in: folder.id) }
                #endif
                Button("New Subfolder…", systemImage: "folder.badge.plus") { presentation.sheet = .folder(parentID: folder.id) }
                Button("Rename and Customize…", systemImage: "paintpalette") { presentation.sheet = .rename(folder.id, folder.name) }
                Menu("Move To", systemImage: "folder") {
                    Button("Root") { store.moveFolder(folder.id, to: nil) }
                        .disabled(!store.canMoveFolder(folder.id, to: nil))
                    ForEach(store.folders.destinations(excluding: folder.id)) { destination in
                        Button(destination.title) { store.moveFolder(folder.id, to: destination.id) }
                            .disabled(!store.canMoveFolder(folder.id, to: destination.id))
                    }
                }
                Divider()
                Button("Dissolve Folder", systemImage: "folder.badge.minus") { store.removeFolder(folder.id) }
            }
        }
    }
}
