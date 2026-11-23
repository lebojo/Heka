import SwiftUI

struct SessionComposerPasteChip: View {
    @Environment(ChatDrafts.self) private var drafts
    @Environment(SessionChat.self) private var chat

    @Binding var previewed: ChatPaste?

    let paste: ChatPaste

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Button { previewed = paste } label: {
                Label(paste.token, systemImage: "doc.plaintext")
                    .lineLimit(1)
            }
            .help("Show Pasted Text")
            Button { drafts[terminal: chat.terminal].removePaste(paste) } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.textTertiary)
            }
            .accessibilityLabel("Remove Pasted Text")
            .help("Remove Pasted Text")
        }
        .buttonStyle(.plain)
        .font(Font.captionMono)
        .foregroundStyle(Color.textSecondary)
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.xs)
        .background(Color.fill.opacity(0.4), in: .rect(cornerRadius: Radius.m))
        .accessibilityElement(children: .contain)
    }
}
