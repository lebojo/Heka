import SwiftUI
import Textual

struct SessionCodeBlockStyle: StructuredText.CodeBlockStyle {
    func makeBody(configuration: Configuration) -> some View {
        let block = SessionCodeBlockHint(hint: configuration.languageHint)
        VStack(alignment: .leading, spacing: Spacing.s) {
            if let language = block?.language, !language.isEmpty {
                Text(verbatim: language).font(Font.caption).foregroundStyle(Color.textSecondary)
            }
            Overflow {
                Group {
                    if let block {
                        InlineText(block.code, parser: SessionCodeHighlighter(language: block.language))
                    } else {
                        configuration.label
                    }
                }
                .font(Font.code)
                .fixedSize(horizontal: false, vertical: true)
            }
        }.padding(Spacing.m)
            .background(Color.fill.opacity(0.5), in: RoundedRectangle(cornerRadius: Radius.s))
            .textual.blockSpacing(.fontScaled(top: 0.5, bottom: 1))
    }
}
