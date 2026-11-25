import SwiftUI

struct SessionComposerThumbnail: View {
    @Environment(ChatDrafts.self) private var drafts
    @Environment(SessionChat.self) private var chat

    let image: URL

    var body: some View {
        AsyncImage(url: image) { picture in
            picture.resizable().scaledToFill()
        } placeholder: {
            Color.textTertiary.opacity(0.2)
        }
        .frame(width: Dimension.Chat.attachmentSize, height: Dimension.Chat.attachmentSize)
        .clipShape(.rect(cornerRadius: Radius.m))
        .overlay(alignment: .topTrailing) {
            SessionComposerRemoveButton(title: "Remove Image") { drafts.remove(image, from: chat.terminal) }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Attached Image")
    }
}
