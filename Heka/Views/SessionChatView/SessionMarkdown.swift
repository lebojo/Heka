import SwiftUI
import Textual

struct SessionMarkdown: View {
    let text: String

    private var webLinksOnly: OpenURLAction {
        OpenURLAction { url in ["http", "https"].contains(url.scheme) ? .systemAction : .discarded }
    }

    private var inlineStyle: InlineStyle {
        InlineStyle()
            .code(.monospaced, .backgroundColor(Palette.fill.opacity(0.4)))
            .link(.foregroundColor(Palette.accent))
    }

    var body: some View {
        StructuredText(text, parser: SessionMarkdownParser())
            .font(.system(size: Typography.chatBodySize))
            .foregroundStyle(Palette.textPrimary)
            .textual.inlineStyle(inlineStyle)
            .textual.codeBlockStyle(SessionCodeBlockStyle())
            .textual.tableStyle(SessionTableStyle())
            .textual.imageAttachmentLoader(SessionBlockedImageLoader())
            .textual.textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .environment(\.openURL, webLinksOnly)
    }
}
