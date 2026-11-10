import SwiftUI

enum WorkspaceSheet: Identifiable, Equatable {
    case folder(parentID: UUID?)
    case rename(UUID, String)
    case worktree(UUID, String)
    case worktreeGroup(projectID: UUID, worktreeID: UUID?)
    var id: String {
        switch self {
        case .folder(let parentID): "folder-\(parentID?.uuidString ?? "root")"
        case .rename(let id, _): "rename-\(id)"
        case .worktree(let id, _): "worktree-\(id)"
        case .worktreeGroup(let projectID, let worktreeID): "worktree-group-\(projectID)-\(worktreeID?.uuidString ?? "empty")"
        }
    }
}

struct WorkspaceEditor: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var submitting = false
    @State private var submission: Task<Void, Never>?
    @State private var error: String?
    @State private var appearance: SidebarAppearance?
    @State private var launch = AgentLaunch()
    @State private var branches: [BranchSuggestion] = []
    @State private var fetching = false

    @FocusState private var focused: Bool

    let store: any WorkspaceEditing
    let sheet: WorkspaceSheet
    let defaultLaunch: AgentLaunch
    let agents: [ConversationAgent]

    private var isWorktree: Bool { worktreeProject != nil }
    private var worktreeProject: UUID? { if case .worktree(let id, _) = sheet { id } else { nil } }
    private var suggestions: [BranchSuggestion] {
        let query = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return Array(branches.lazy.filter { $0.matches(query) }.prefix(12))
    }
    private var title: String {
        switch sheet {
        case .folder(nil): String(localized: "New Virtual Folder")
        case .folder: String(localized: "New Subfolder")
        case .rename: appearance == nil ? String(localized: "Rename") : String(localized: "Edit")
        case .worktree: String(localized: "New Worktree")
        case .worktreeGroup: String(localized: "New Worktree Group")
        }
    }
    private var explanation: String {
        switch sheet {
        case .folder: String(localized: "Gather projects from different places on your Mac. Their files stay where they are.")
        case .rename: appearance == nil ? String(localized: "This name will be shown in the sidebar.") : String(localized: "This name, icon and color will be shown in the sidebar.")
        case .worktree(_, let project): String(localized: "Opens the branch in a separate working folder. If it doesn’t exist yet, it’s created from HEAD of \(project). \(worktreeLaunchDescription)")
        case .worktreeGroup: String(localized: "Groups the project’s worktrees under one name in the sidebar. Their folders and branches don’t change.")
        }
    }

    private var placeholder: String {
        switch sheet {
        case .worktree: String(localized: "feature/my-task")
        case .worktreeGroup: String(localized: "Reviews")
        case .folder, .rename: String(localized: "My Projects")
        }
    }

    private var symbol: String {
        switch sheet {
        case .worktree: "arrow.triangle.branch"
        case .worktreeGroup: "rectangle.stack"
        case .folder, .rename: "pencil"
        }
    }

    private var worktreeLaunchDescription: String {
        launch.launches(on: .newWorktree) ? String(localized: "\(launch.agent.title) will be launched there.") : String(localized: "A terminal will be opened there.")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            Label {
                Text(title)
            } icon: {
                Image(systemName: appearance?.displaySymbol.systemName ?? symbol)
                    .foregroundStyle(appearance?.color ?? Palette.accent)
            }
            .font(Typography.title)
            Text(explanation).foregroundStyle(Palette.textSecondary).font(Typography.body).fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text(isWorktree ? "Branch" : "Name").font(Typography.label)
                HStack(spacing: Spacing.s) {
                    TextField(placeholder, text: $name)
                        .textFieldStyle(.roundedBorder).focused($focused)
                        .onSubmit { submit() }.disabled(submitting)
                        .modifier(BranchSuggestions(suggestions: suggestions))
                    if let project = worktreeProject {
                        if fetching {
                            ProgressView().controlSize(.small)
                        } else {
                            Button("Fetch Remote Branches", systemImage: "arrow.clockwise") { fetchRemotes(of: project) }
                                .labelStyle(.iconOnly).help("Fetch Remote Branches")
                                .disabled(submitting || store.busyProjects.contains(project))
                        }
                    }
                }
            }
            if isWorktree {
                WorktreeLaunchPicker(launch: $launch, agents: agents).disabled(submitting)
            }
            if let appearance = Binding($appearance) {
                SidebarAppearancePicker(appearance: appearance)
            }
            if let error {
                Text(error).font(Typography.body).foregroundStyle(Palette.danger).textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                if submitting {
                    ProgressView().controlSize(.small)
                    if isWorktree { Text("Creating worktree…").font(Typography.caption).foregroundStyle(Palette.textSecondary) }
                }
                Spacer()
                Button(submitting ? "Stop" : "Cancel") {
                    if submitting { submission?.cancel() } else { dismiss() }
                }.keyboardShortcut(.cancelAction)
                Button(isWorktree ? "Create Worktree" : "Save") { submit() }
                    .keyboardShortcut(.defaultAction).buttonStyle(.borderedProminent)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || submitting || fetching || store.isReadOnly)
            }
        }
        .padding(Spacing.xxl).modifier(EditorSheetFrame())
        .interactiveDismissDisabled(submitting)
        .onAppear {
            switch sheet {
            case .folder: appearance = SidebarAppearance(kind: .folder)
            case .rename(let id, let current):
                name = current
                appearance = store.appearance(of: id)
            case .worktree:
                launch = defaultLaunch
            case .worktreeGroup: break
            }
            focused = true
        }
        .task {
            guard let project = worktreeProject else { return }
            branches = await store.availableBranches(projectID: project)
        }
    }

    private func submit() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !submitting, !fetching, !store.isReadOnly else { return }
        submitting = true
        error = nil
        submission = Task {
            do { try await save(trimmed); dismiss() }
            catch is CancellationError { self.error = String(localized: "Creation cancelled.") }
            catch { self.error = error.localizedDescription }
            submitting = false
            submission = nil
        }
    }

    private func save(_ name: String) async throws {
        switch sheet {
        case .folder(let parentID):
            try await store.addFolder(name, parentID: parentID, appearance: appearance)
        case .rename(let id, _):
            try await store.rename(id, to: name, appearance: appearance)
        case .worktreeGroup(let project, let worktree):
            _ = try await store.addWorktreeGroup(name, projectID: project, moving: worktree)
        case .worktree(let project, _):
            let remote = branches.first { $0.name == name }?.remote
            try await store.openWorktree(projectID: project, branch: name, remote: remote, launch: launch)
        }
    }

    private func fetchRemotes(of project: UUID) {
        fetching = true
        error = nil
        Task {
            do { try await store.fetchRemotes(projectID: project) }
            catch { self.error = error.localizedDescription }
            branches = await store.availableBranches(projectID: project)
            fetching = false
        }
    }
}

private struct EditorSheetFrame: ViewModifier {
    func body(content: Content) -> some View {
        #if os(macOS)
        content.frame(width: Dimension.Sheet.width)
        #else
        ScrollView { content }.presentationDetents([.medium, .large])
        #endif
    }
}
