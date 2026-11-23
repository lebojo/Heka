import SwiftUI

struct DiffCode: View {
    let line: GitDiffLine
    let changedRanges: [Range<Int>]

    private var code: AttributedString {
        var code = AttributedString(line.text)
        for range in changedRanges {
            let lower = code.characters.index(code.startIndex, offsetBy: range.lowerBound)
            let upper = code.characters.index(lower, offsetBy: range.count)
            code[lower..<upper].backgroundColor = line.kind.emphasis
        }
        var endingSymbols = AttributedString(line.endingSymbols)
        endingSymbols.foregroundColor = Color.textTertiary
        return code + endingSymbols
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(line.kind.marker).foregroundStyle(line.kind.markerColor)
                .frame(width: Dimension.DiffSheet.markerWidth)
                .textSelection(.disabled)
            Text(code)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.code)
        .padding(.leading, Spacing.xs)
        .padding(.vertical, Spacing.xxs / 2)
        .help(line.missingFinalNewline ? String(localized: "No newline at end of file") : "")
    }
}
