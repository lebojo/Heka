import AppKit
import SwiftUI

struct TerminalDetail: View {
    let store: WorkspaceStore
    let context: TerminalContext

    private var layout: TerminalLayout { store.layout(for: context.terminal.id) }
    private var panes: [UUID: TerminalPane] {
        let layout = layout
        return layout.terminalIDs.reduce(into: [:]) { panes, id in
            guard let pane = store.context(for: id) else { return }
            panes[id] = TerminalPane(store: store, context: pane, isFocused: id == context.terminal.id, isSplit: layout.isSplit)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            TerminalHeader(store: store, context: context)

            Divider()

            TerminalLayoutView(layout: layout, panes: panes)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
            TerminalFooter(session: store.sessions.session(context.terminal.id), path: context.worktree.path)
        }
        .background(Color.surface)
        .navigationTitle(context.terminal.name)
    }
}
