import SwiftUI

struct SplitDiffSide: View {
    let line: GitDiffLine?
    let number: Int?
    let changedRanges: [Range<Int>]
    let digits: Int

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            if let line {
                DiffLineNumber(number: number, digits: digits)
                DiffCode(line: line, changedRanges: changedRanges)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(line?.kind.background ?? Color.fill)
    }
}
