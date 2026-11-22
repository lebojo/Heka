import SwiftUI

extension GitChangeKind {
    var color: Color {
        switch self {
        case .modified, .typeChanged: Color.warning
        case .added, .untracked, .copied: Color.success
        case .deleted, .conflicted: Color.danger
        case .renamed: Color.accentColor
        }
    }
}
