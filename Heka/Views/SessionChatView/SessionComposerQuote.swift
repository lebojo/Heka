import SwiftUI

struct SessionComposerQuote: View {
    @Environment(ChatDrafts.self) private var drafts
    @Environment(SessionChat.self) private var chat

    let quote: ChatQuote

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(verbatim: quote.preview)
                .font(Font.label)
                .foregroundStyle(Color.textPrimary)
            Label {
                if quote.note.isEmpty {
                    Text("Quotation")
                } else {
                    Text(verbatim: quote.note)
                }
            } icon: {
                Image(systemName: "text.quote")
            }
            .font(Font.caption)
            .foregroundStyle(Color.textSecondary)
        }
        .lineLimit(1)
        .padding(.leading, Spacing.m)
        .padding(.trailing, Spacing.xl)
        .frame(width: Dimension.Chat.quoteCardWidth, height: Dimension.Chat.attachmentSize, alignment: .leading)
        .background(Color.fill.opacity(0.3), in: RoundedRectangle(cornerRadius: Radius.m))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.m)
                .strokeBorder(Color.textTertiary.opacity(0.4), lineWidth: Stroke.hairline)
        }
        .overlay(alignment: .topTrailing) {
            SessionComposerRemoveButton(title: "Remove Quote") { drafts.remove(quote, from: chat.terminal) }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Quotation")
        .accessibilityValue(quote.preview)
    }
}
