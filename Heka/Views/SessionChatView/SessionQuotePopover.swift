import SwiftUI

struct SessionQuotePopover: View {
    @Environment(ChatDrafts.self) private var drafts
    @Environment(\.dismiss) private var dismiss

    @State private var comment = ""

    @FocusState private var isCommentFocused: Bool

    let message: SessionMessage
    let terminal: UUID

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            Text(verbatim: message.text.trimmingCharacters(in: .whitespacesAndNewlines))
                .font(Font.chatBody)
                .foregroundStyle(Color.textSecondary)
                .lineLimit(3)
                .padding(.leading, Spacing.m)
                .overlay(alignment: .leading) {
                    Capsule().fill(Color.textTertiary).frame(width: Stroke.regular)
                }
                .accessibilityLabel("Quoted Text")
            HStack(spacing: Spacing.m) {
                TextField("Add an optional comment…", text: $comment)
                    .textFieldStyle(.plain)
                    .focused($isCommentFocused)
                    .onSubmit(confirm)
                Button("Add Quote", systemImage: "checkmark", action: confirm)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .help("Add Quote")
            }
        }
        .padding(Spacing.l)
        .frame(width: Dimension.Chat.quotePopoverWidth, alignment: .leading)
        .onAppear { isCommentFocused = true }
    }

    private func confirm() {
        if let quote = ChatQuote(quoting: message, comment: comment) {
            drafts.add(quote, to: terminal)
        }
        dismiss()
    }
}
