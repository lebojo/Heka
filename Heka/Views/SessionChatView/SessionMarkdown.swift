import MarkdownUI
import SwiftUI

struct SessionMarkdown: View {
    let text: String

    private var webLinksOnly: OpenURLAction {
        OpenURLAction { url in ["http", "https"].contains(url.scheme) ? .systemAction : .discarded }
    }

    var body: some View {
        Markdown(text)
            .markdownTextStyle {
                FontSize(Typography.chatBodySize)
                ForegroundColor(Palette.textPrimary)
            }
            .markdownTextStyle(\.link) { ForegroundColor(Palette.accent) }
            .markdownTextStyle(\.code) {
                FontFamilyVariant(.monospaced)
                BackgroundColor(Palette.fill.opacity(0.4))
            }
            .markdownBlockStyle(\.codeBlock) { configuration in
                SessionCodeBlock(code: configuration.content, language: configuration.language ?? "")
                    .markdownMargin(top: .em(0.5), bottom: .em(1))
            }
            .markdownBlockStyle(\.table) { configuration in
                ScrollView(.horizontal) {
                    configuration.label
                        .fixedSize(horizontal: false, vertical: true)
                }
                .markdownMargin(top: .em(0.5), bottom: .em(1))
            }
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .environment(\.openURL, webLinksOnly)
    }
}
