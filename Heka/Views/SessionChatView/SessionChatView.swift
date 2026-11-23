import SwiftUI

struct SessionChatView: View {
    @AppStorage(ChatTheme.storageKey) private var theme = ChatTheme.system

    @Environment(\.colorScheme) private var colorScheme

    @State private var chat: SessionChat

    let messages: [SessionMessage]
    let source: SessionChatSource
    let options: AgentOptions
    let commands: [SlashCommand]
    let isEnabled: Bool
    let status: AgentStatus?

    private var activity: ChatActivity {
        ChatActivity(status: status, isSending: chat.isSending || chat.awaitsAgent, isEnabled: isEnabled)
    }

    private var isAgentWorking: Bool {
        source.agent != nil && activity.showsIndicator
    }

    var body: some View {
        SessionTranscriptList(messages: messages, source: source, showsTypingIndicator: isAgentWorking)
        .background(.background)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SessionComposer(source: source, options: options, commands: commands, isEnabled: isEnabled,
                            isBusy: !(status?.acceptsCommands ?? true), isWorking: isAgentWorking,
                            isInterruptible: activity.allowsInterrupt(from: source, status: status))
        }
        .backgroundStyle(theme.surface)
        .environment(\.colorScheme, theme.colorScheme(following: colorScheme))
        .environment(chat)
        .onChange(of: status) { chat.awaitsAgent = false }
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
