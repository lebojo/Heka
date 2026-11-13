import SwiftUI

struct LocalSessionChat: View {
    let session: TerminalSession

    var body: some View {
        SessionChatView(messages: session.transcript.messages, source: session.transcript.source,
                        options: session.transcript.options, isEnabled: !session.hasExited,
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
    }
}
