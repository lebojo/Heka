import SwiftUI

struct DiffSectionRows: View {
    let section: GitDiffSection
    let layout: DiffLayout
    let digits: Int

    var body: some View {
        switch layout {
        case .unified: ForEach(section.lines) { UnifiedDiffRow(line: $0, digits: digits) }
        case .split: ForEach(section.rows) { SplitDiffRow(row: $0, digits: digits) }
        }
    }
}
