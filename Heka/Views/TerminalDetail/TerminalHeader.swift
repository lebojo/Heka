import AppKit
import SwiftUI

struct TerminalHeader: View {
    @Environment(SettingsStore.self) private var settings

    let store: WorkspaceStore
    let context: TerminalContext

    var body: some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: "shippingbox").foregroundStyle(Color.textSecondary)
            Text(context.project.name).fontWeight(.medium)
            Image(systemName: "chevron.right").font(Font.xxs).foregroundStyle(Color.textTertiary)
            Image(systemName: "arrow.triangle.branch").foregroundStyle(Color.textSecondary)
            Text(context.worktree.name).foregroundStyle(Color.textSecondary)
            if let branch = store.sessions.branch(for: context.terminal.id, initialPath: context.worktree.path) {
                BranchBadge(branch: branch).frame(maxWidth: Dimension.Badge.detailMaxWidth)
            }
            Spacer()
            Button { split(.horizontal) } label: { Image(systemName: "rectangle.split.2x1") }
                .buttonStyle(.borderless).help(Text("Split Right (\(ShortcutAction.splitRight.symbols))"))
                .accessibilityLabel("Split terminal right")
                .keyboardShortcut(.splitRight)
            Button { split(.vertical) } label: { Image(systemName: "rectangle.split.1x2") }
                .buttonStyle(.borderless).help(Text("Split Down (\(ShortcutAction.splitDown.symbols))"))
                .accessibilityLabel("Split terminal down")
                .keyboardShortcut(.splitDown)
            Button(action: addTerminal) { Label("Terminal", systemImage: "plus") }
                .buttonStyle(.borderless).help("New terminal in this worktree")
                .keyboardShortcut(.newTerminal)
        }
        .font(Font.m).lineLimit(1).padding(.horizontal, Spacing.xl).frame(height: Dimension.Detail.headerHeight)
    }

    private func addTerminal() {
        guard let current = store.selectedContext else { return }
        do {
            _ = try store.addTerminal(projectID: current.project.id, worktreeID: current.worktree.id,
                                      command: settings.agentLaunch.command(on: .newTerminal))
        }
        catch { store.errorMessage = error.localizedDescription }
    }

    private func split(_ axis: SplitAxis) {
        guard let current = store.selectedContext else { return }
        do {
            _ = try store.splitTerminal(current.terminal.id, axis: axis, command: settings.agentLaunch.command(on: .newTerminal))
        }
        catch { store.errorMessage = error.localizedDescription }
    }
}
