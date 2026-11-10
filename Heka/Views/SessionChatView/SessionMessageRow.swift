import SwiftUI

struct SessionMessageRow: View, Equatable {
    let message: SessionMessage
    let agent: ConversationAgent?

    var body: some View {
        switch message.kind {
        case .input:
            HStack(alignment: .top) {
                Spacer(minLength: Spacing.xxl)
                Text(verbatim: message.text)
                    .font(.body).textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(Spacing.l)
                    .background(Palette.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: Radius.l))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("You")
                    .accessibilityValue(message.text)
            }
        case .assistant:
            VStack(alignment: .leading, spacing: Spacing.m) {
                Text(verbatim: agent?.title ?? "Agent")
                    .font(Typography.caption).foregroundStyle(Palette.textSecondary)
                SessionMarkdown(text: message.text)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .tool:
            let questions = message.userQuestions
            if questions.isEmpty {
                SessionToolMessage(message: message)
            } else {
                SessionQuestionMessage(message: message, questions: questions)
            }
        case .output, .notice:
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text("Session Output").font(Typography.caption).foregroundStyle(Palette.textSecondary)
                Text(verbatim: message.text.isEmpty ? "…" : message.text)
                    .font(Typography.chatOutput).textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct SessionToolMessage: View {
    let message: SessionMessage

    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: Spacing.m) {
                if let detail = message.detail, !detail.isEmpty, detail != message.text {
                    Text(verbatim: detail).font(Typography.code).textSelection(.enabled)
                    Divider()
                }
                Text(verbatim: message.text).font(Typography.code).textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(Spacing.l)
            .background(Palette.fill.opacity(0.3), in: RoundedRectangle(cornerRadius: Radius.m))
        } label: {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Label(message.title ?? String(localized: "Tool"), systemImage: message.toolState == .failed ? "exclamationmark.circle" : (message.toolState == .completed ? "checkmark.circle" : "gearshape"))
                    .font(Typography.caption).foregroundStyle(message.toolState == .failed ? Palette.danger : Palette.textSecondary)
                if let detail = message.detail, !detail.isEmpty {
                    Text(verbatim: detail).font(Typography.code).foregroundStyle(Palette.textSecondary)
                        .lineLimit(2).frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}
