import SwiftUI

struct SplitDiffRow: View {
    let row: GitDiffRow
    let changes: IntraLineDiff?
    let digits: Int

    var body: some View {
        VStack(spacing: 0) {
            switch row.content {
            case .banner(let line):
                DiffBanner(line: line)
            case .pair(let old, let new):
                HStack(spacing: 0) {
                    SplitDiffSide(line: old, number: old?.oldNumber, changedRanges: changes?.old ?? [], digits: digits)
                    Divider()
                    SplitDiffSide(line: new, number: new?.newNumber, changedRanges: changes?.new ?? [], digits: digits)
                }.fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
