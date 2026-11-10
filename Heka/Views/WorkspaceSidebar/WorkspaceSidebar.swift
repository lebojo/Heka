import AppKit
import SwiftUI

struct WorkspaceSidebar: View {
    @Environment(WorkspaceStore.self) private var store
    @Environment(WorkspacePresentation.self) private var presentation

    @State private var search = ""
    @State private var filtered = SidebarFilterResult()

    private var hasNoResults: Bool {
        !search.isEmpty && filtered.groups.isEmpty && filtered.ungrouped.isEmpty
            && !store.orphanWorktrees.contains { $0.folderName.localizedStandardContains(search) || ($0.branch?.localizedStandardContains(search) ?? false) }
    }

    @ViewBuilder private var emptyState: some View {
        if store.projects.isEmpty && store.folders.isEmpty && store.orphanWorktrees.isEmpty {
            VStack(spacing: Spacing.m) {
                Image(systemName: "folder.badge.plus").font(Typography.emptyStateSymbol)
                Text("All your projects in one place").font(Typography.m.weight(.medium))
                Text("Add a project to get started.").font(Typography.s).foregroundStyle(Palette.textSecondary)
                Button("Add Project…") { store.chooseProjects() }.controlSize(.small).padding(.top, Spacing.xs)
            }
            .foregroundStyle(Palette.textSecondary)
            .padding()
        } else if hasNoResults {
            Text("No Results").font(Typography.body).foregroundStyle(Palette.textSecondary)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Projects").font(Typography.headline)
                Spacer()
                Menu {
                    Button("Add Project…", systemImage: "folder.badge.plus") { store.chooseProjects() }
                        .keyboardShortcut("o")
                    Button("Import Folder…", systemImage: "square.and.arrow.down") { store.chooseFolder() }
                    Divider()
                    Button("New Virtual Folder…", systemImage: "folder.badge.plus") { presentation.sheet = .folder(parentID: nil) }
                        .keyboardShortcut("n", modifiers: [.command, .shift])
                } label: {
                    Image(systemName: "plus").frame(width: IconSize.l, height: IconSize.l)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .help("Add projects or a virtual folder")
                .accessibilityLabel("Add projects or a virtual folder")
                .disabled(store.isReadOnly || store.isImporting)
            }
            .padding(.horizontal, Spacing.l).padding(.top, Spacing.m)
            HStack(spacing: Spacing.s) {
                Image(systemName: "magnifyingglass").foregroundStyle(Palette.textSecondary)
                TextField("Filter projects and terminals", text: $search)
                    .textFieldStyle(.plain)
                    .accessibilityLabel("Filter projects and terminals")
                if !search.isEmpty {
                    Button { search = "" } label: { Image(systemName: "xmark.circle.fill") }
                        .buttonStyle(.plain).foregroundStyle(Palette.textSecondary).accessibilityLabel("Clear Filter")
                }
            }
            .font(Typography.m)
            .padding(Spacing.m)
            .background(Palette.searchFieldFill, in: RoundedRectangle(cornerRadius: Radius.m))
            .padding(.horizontal, Spacing.l).padding(.top, Spacing.m).padding(.bottom, Spacing.l)

            SidebarProjectList(result: filtered, query: search)
                .safeAreaInset(edge: .bottom, spacing: 0) { UsageBar() }
                .overlay { emptyState }
            SidebarFooter()
        }
        .toolbar {
            ToolbarItem { FloatingTerminalButton() }
        }
        .onChange(of: SidebarFilterInput(folders: store.folders, projects: store.projects, query: search), initial: true) { _, input in
            filtered = input.filtered()
        }
    }
}
