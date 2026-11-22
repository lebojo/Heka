import SwiftUI

struct LocalSessionChat: View {
    @State private var commands: [SlashCommand] = []

    let session: TerminalSession

    private var commandScope: String {
        [session.transcript.source.rawValue, session.path, session.agent?.configDirectory?.path ?? ""].joined(separator: "\u{0}")
    }

    var body: some View {
        SessionChatView(channel: session, messages: session.transcript.messages, source: session.transcript.source,
                        options: session.transcript.options, commands: commands, isEnabled: !session.hasExited,
                        status: session.agentStatus)
        .id(session.identity)
        .task(id: session.identity) {
            session.acquireChat()
            await Task.waitUntilCancelled()
            session.releaseChat()
        }
        .task(id: commandScope) {
            let source = session.transcript.source
            commands = source.slashCommands
            let discovered = await SlashCommandDiscovery.commands(for: source, directory: session.path,
                                                                 configDirectory: session.agent?.configDirectory)
            guard !Task.isCancelled else { return }
            commands = discovered
        }
    }
}
