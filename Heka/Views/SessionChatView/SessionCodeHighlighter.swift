import SwiftUI
import Textual

struct SessionCodeHighlighter: MarkupParser {
    let language: String

    func attributedString(for input: String) throws -> AttributedString {
        var result = AttributedString(input)
        for token in SessionCodeTokens.parse(input, language: language) {
            guard let range = Range(token.range, in: input),
                  let lower = AttributedString.Index(range.lowerBound, within: result),
                  let upper = AttributedString.Index(range.upperBound, within: result) else { continue }
            result[lower..<upper].foregroundColor = token.kind.color
        }
        return result
    }
}

private extension SessionCodeTokens.Kind {
    var color: Color {
        switch self {
        case .comment: Palette.textSecondary
        case .string: Palette.codeString
        case .number: Palette.codeNumber
        case .keyword: Palette.codeKeyword
        case .addition: Palette.success
        case .deletion: Palette.danger
        }
    }
}
