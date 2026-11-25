import SwiftUI

struct TerminalPane: View {
    let store: WorkspaceStore
    let context: TerminalContext
    let isFocused: Bool
    let isSplit: Bool

    private var session: TerminalSession? { store.sessions.session(context.terminal.id) }
    private var startableTerminal: UUID? { store.startableContext(for: context.terminal.id)?.terminal.id }

    var body: some View {
        VStack(spacing: 0) {
            if isSplit {
                TerminalPaneHeader(title: context.terminal.name,
                                   branch: store.sessions.branch(for: context.terminal.id, initialPath: context.worktree.path),
                                   isFocused: isFocused) { store.closeTerminal(context.terminal.id) }
                    .onTapGesture { select() }
                    .terminalDragSource(context.terminal.id)
                Divider()
            }
            if let session {
                LocalSessionContent(session: session, isFocused: isFocused) { select() }
                SessionEndedBar(session: session) {
                    store.sessions.close(context.terminal.id)
                    store.startSession(for: context.terminal.id)
                }
            } else if store.isRemovingWorktree(containing: context.terminal.id) {
                ContentUnavailableView("This worktree is being deleted.", systemImage: "trash")
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task(id: startableTerminal) { store.startSession(for: context.terminal.id) }
        .terminalDropZone(context.terminal.id)
    }

    private func select() {
        if store.selection != context.terminal.id { store.selection = context.terminal.id }
    }
}
