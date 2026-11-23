import SwiftUI

struct DiffSectionRows: View {
    let section: GitDiffSection
    let layout: DiffLayout
    let digits: Int
    let highlightsChanges: Bool

    var body: some View {
        switch layout {
        case .unified:
            ForEach(section.lines) { line in
                UnifiedDiffRow(line: line, changedRanges: highlightsChanges ? section.changedRanges(of: line) : [], digits: digits)
            }
        case .split:
            ForEach(section.rows) { row in
                SplitDiffRow(row: row, changes: highlightsChanges ? section.changes(in: row) : nil, digits: digits)
            }
        }
    }
}
