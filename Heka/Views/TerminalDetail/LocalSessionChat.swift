import SwiftUI

struct LocalSessionChat: View {
    @State private var commands: [SlashCommand] = []

    let session: TerminalSession

    private var commandScope: String {
        session.transcript.source.rawValue + "\u{0}" + session.path
    }

    var body: some View {
        SessionChatView(messages: session.transcript.messages, source: session.transcript.source,
                        options: session.transcript.options, commands: commands, isEnabled: !session.hasExited,
                        isBusy: session.agentStatus == .working) { text in
            try await session.send(Data((text + "\r").utf8), message: text, from: .local)
        } control: { data in
            try await session.send(data, from: .local)
        } run: { command in
            try await session.run(command, from: .local)
        }
        .id(session.terminalID)
        .task(id: session.identity) {
            session.acquireChat()
            await Task.waitUntilCancelled()
            session.releaseChat()
        }
        .task(id: commandScope) {
            let source = session.transcript.source
            commands = source.slashCommands
            commands = await SlashCommandDiscovery.commands(for: source, directory: session.path)
        }
    }
}
