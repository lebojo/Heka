import SwiftUI

struct SessionMessageRow: View, Equatable {
    let message: SessionMessage
    let agent: ConversationAgent?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch message.presentation {
            case .input:
                SessionInputMessage(text: message.text)
            case .assistant:
                VStack(alignment: .leading, spacing: Spacing.m) {
                    SessionAgentHeader(agent: agent)
                    SessionMarkdown(text: message.text)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            case .tool:
                SessionToolMessage(message: message)
            case .question(let questions):
                SessionQuestionMessage(message: message, questions: questions)
            case .output:
                VStack(alignment: .leading, spacing: Spacing.s) {
                    Text("Session Output").font(Font.caption).foregroundStyle(Color.textSecondary)
                    Text(verbatim: message.text.isEmpty ? "…" : message.text)
                        .font(Font.chatOutput).textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
