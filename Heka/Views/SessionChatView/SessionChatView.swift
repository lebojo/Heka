import SwiftUI

struct SessionChatView: View {
    @State private var chat: SessionChat

    let messages: [SessionMessage]
    let source: SessionChatSource
    let options: AgentOptions
    let commands: [SlashCommand]
    let isEnabled: Bool
    let status: AgentStatus?

    private var isAgentWorking: Bool {
        source.agent != nil && ChatActivity(status: status, isSending: chat.isSending || chat.awaitsAgent, isEnabled: isEnabled).showsIndicator
    }

    private var unconfirmedCandidates: [UUID] {
        isAgentWorking ? [] : chat.sendingPendingIDs
    }

    var body: some View {
        SessionTranscriptList(messages: messages, pending: chat.pendingMessages, source: source, showsTypingIndicator: isAgentWorking)
        .background(Color.surface)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SessionComposer(source: source, options: options, commands: commands, isEnabled: isEnabled,
                            isBusy: !(status?.acceptsCommands ?? true), isWorking: isAgentWorking)
        }
        .environment(chat)
        .onChange(of: status) { chat.awaitsAgent = false }
        .onChange(of: messages, initial: true) { chat.reconcilePending(with: messages) }
        .task(id: unconfirmedCandidates) {
            let candidates = unconfirmedCandidates
            guard !candidates.isEmpty else { return }
            try? await Task.sleep(for: PendingChatMessages.confirmationGrace)
            guard !Task.isCancelled else { return }
            chat.markPendingUnconfirmed(candidates)
        }
        .task(id: chat.awaitsAgent) {
            guard chat.awaitsAgent else { return }
            try? await Task.sleep(for: ChatActivity.agentStartGrace)
            chat.awaitsAgent = false
        }
        .alert("Couldn’t Send", isPresented: $chat.error.isPresent) {
            Button("OK") { chat.error = nil }
        } message: { Text(chat.error ?? "") }
    }

    init(channel: any SessionChannel, messages: [SessionMessage], source: SessionChatSource, options: AgentOptions,
         commands: [SlashCommand], isEnabled: Bool, status: AgentStatus?) {
        _chat = State(initialValue: SessionChat(channel: channel))
        self.messages = messages
        self.source = source
        self.options = options
        self.commands = commands
        self.isEnabled = isEnabled
        self.status = status
    }
}
