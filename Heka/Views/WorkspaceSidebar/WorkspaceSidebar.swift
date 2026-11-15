import AppKit
import SwiftUI

struct WorkspaceSidebar: View {
    @Environment(WorkspaceStore.self) private var store
    @Environment(WorkspacePresentation.self) private var presentation

    @State private var page = SidebarPage.projects
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

    @ViewBuilder private var pageContent: some View {
        switch page {
        case .projects:
            SidebarProjectList(result: filtered, query: search)
                .overlay { emptyState }
        case .workInProgress:
            SidebarWorkInProgressList(query: search)
        }
    }

    private var addMenu: some View {
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

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(page.title).font(Typography.headline)
                Spacer()
                if page == .projects { addMenu }
            }
            .frame(minHeight: IconSize.l)
            .padding(.horizontal, Spacing.l).padding(.top, Spacing.m)

            SearchField(text: $search, prompt: page.searchPrompt)
                .padding(.horizontal, Spacing.l).padding(.top, Spacing.m).padding(.bottom, Spacing.l)

            pageContent
                .safeAreaInset(edge: .bottom, spacing: 0) { UsageBar() }

            SidebarFooter()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Sidebar Page", selection: $page) {
                    ForEach(SidebarPage.allCases) { page in
                        Label(page.title, systemImage: page.systemImage).tag(page)
                    }
                }
                .pickerStyle(.segmented)
                .labelStyle(.iconOnly)
            }

            ToolbarItem(placement: .primaryAction) {
                FloatingTerminalButton()
            }
        }
        .onChange(of: SidebarFilterInput(folders: store.folders, projects: store.projects, query: search), initial: true) { _, input in
            filtered = input.filtered()
        }
    }
}
