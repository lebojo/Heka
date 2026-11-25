import SwiftUI

struct UnifiedDiffRow: View {
    let line: GitDiffLine
    let changedRanges: [Range<Int>]
    let digits: Int

    var body: some View {
        VStack(spacing: 0) {
            if line.kind.isBanner {
                DiffBanner(line: line)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    DiffLineNumber(number: line.oldNumber, digits: digits)
                    DiffLineNumber(number: line.newNumber, digits: digits)
                    DiffCode(line: line, changedRanges: changedRanges)
                }.background(line.kind.background)
            }
        }
    }
}
