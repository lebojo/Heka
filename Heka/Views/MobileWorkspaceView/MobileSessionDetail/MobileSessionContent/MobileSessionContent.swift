import SwiftUI

struct MobileSessionContent: View {
    let mode: SessionDisplayMode
    let context: TerminalContext
    let session: MobileTerminalSession
    let store: MobileWorkspaceStore

    var body: some View {
        if session.isChat {
            SessionChatView(channel: MobileSessionChannel(store: store, terminalID: context.terminal.id),
                            messages: session.messages, source: session.chatSource, options: session.agentOptions,
                            commands: session.chatSource.slashCommands,
                            isEnabled: store.isConnected && !session.hasExited,
                            status: store.terminalSummary(context.terminal.id)?.status)
            .id(context.terminal.id)
        } else {
            MobileTerminalViewport(session: session)
                .id(session.identity)
                .disabled(!store.isConnected || session.hasExited)
            if mode == .chat, store.isConnected, !session.hasExited, !store.installedAgents.isEmpty {
                AgentShortcutBar(agents: store.installedAgents) { agent in
                    Task { await store.launch(agent, in: context) }
                }
            }
        }
        if session.hasExited {
            SessionExitLabel(code: session.exitCode).font(Font.caption).padding(Spacing.s)
        }
    }
}
