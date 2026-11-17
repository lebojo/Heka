import SwiftUI

struct SessionMessageRow: View, Equatable {
    let message: SessionMessage
    let agent: ConversationAgent?

    var body: some View {
        switch message.presentation {
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
                Text("Session Output").font(Typography.caption).foregroundStyle(Palette.textSecondary)
                Text(verbatim: message.text.isEmpty ? "…" : message.text)
                    .font(Typography.chatOutput).textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct SessionToolMessage: View {
    @Environment(SessionTranscriptExpansion.self) private var expansion

    let message: SessionMessage

    private var isExpanded: Binding<Bool> {
        Binding { expansion.isToolExpanded(message.id) } set: { expansion.setTool(message.id, expanded: $0) }
    }

    var body: some View {
        DisclosureGroup(isExpanded: isExpanded) {
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
                Label(message.title ?? String(localized: "Tool"), systemImage: message.displayedToolState.symbol)
                    .font(Typography.caption).foregroundStyle(message.displayedToolState.tint)
                if let detail = message.detail, !detail.isEmpty {
                    Text(verbatim: detail).font(Typography.code).foregroundStyle(Palette.textSecondary)
                        .lineLimit(2).frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}
