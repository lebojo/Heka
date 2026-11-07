import SwiftUI

struct SessionCodeBlock: View {
    let code: String
    let language: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            if !language.isEmpty {
                Text(verbatim: language).font(Typography.caption).foregroundStyle(Palette.textSecondary)
            }
            ScrollView(.horizontal) {
                Text(highlighted()).font(Typography.code).textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }.padding(Spacing.m)
            .background(Palette.fill.opacity(0.5), in: RoundedRectangle(cornerRadius: Radius.s))
    }

    private func highlighted() -> AttributedString {
        var result = AttributedString(code)
        for token in SessionCodeTokens.parse(code, language: language) {
            guard let range = Range(token.range, in: code),
                  let lower = AttributedString.Index(range.lowerBound, within: result),
                  let upper = AttributedString.Index(range.upperBound, within: result) else { continue }
            result[lower..<upper].foregroundColor = switch token.kind {
            case .comment: Palette.textSecondary
            case .string: Palette.codeString
            case .number: Palette.codeNumber
            case .keyword: Palette.codeKeyword
            case .addition: Palette.success
            case .deletion: Palette.danger
            }
        }
        return result
    }
}
