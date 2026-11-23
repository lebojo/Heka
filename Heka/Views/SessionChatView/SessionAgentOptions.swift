import SwiftUI

struct SessionAgentOptions: View {
    @Environment(SessionChat.self) private var chat

    let source: SessionChatSource
    let reported: AgentOptions
    let isBusy: Bool

    var body: some View {
        HStack(spacing: Spacing.xs) {
            if source == .copilot {
                SessionCopilotModelMenu(reported: reported)
            } else {
                SessionClaudeOptions(source: source, reported: reported)
            }
        }
        .compactMenuStyle()
        .font(Font.caption)
        .disabled(isBusy)
        .onChange(of: reported) { chat.forgetRequestedOptions() }
    }
}
