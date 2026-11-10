import SwiftUI

struct SidebarProjectList: View {
    @Environment(SidebarStore.self) private var store

    let result: SidebarFilterResult
    let query: String

    var body: some View {
        List(selection: Bindable(store).selection) {
            SidebarWorkInProgressSection(query: query)
            Section {
                ForEach(result.groups) { group in
                    SidebarFolderRow(group: group, query: query)
                }
                #if os(macOS)
                .onMove(perform: store.isReadOnly ? nil : { store.reorderFolders(result.groups.map(\.id), from: $0, to: $1) })
                #endif
                ForEach(result.ungrouped) { project in
                    SidebarProjectRow(project: project, query: query, showAll: false)
                }
                #if os(macOS)
                .onMove(perform: store.isReadOnly ? nil : { store.reorderProjects(result.ungrouped.map(\.id), from: $0, to: $1) })
                #endif
            }
            #if os(macOS)
            SidebarOrphanSection(query: query)
            #endif
        }
        .listStyle(.sidebar)
    }
}
