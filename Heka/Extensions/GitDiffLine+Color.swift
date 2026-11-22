import SwiftUI

extension GitDiffLine.Kind {
    var background: Color {
        switch self {
        case .addition: Color.diffAdditionBackground
        case .deletion: Color.diffDeletionBackground
        case .hunk: Color.diffHunkBackground
        case .context, .meta: .clear
        }
    }

    var markerColor: Color {
        switch self {
        case .addition: Color.success
        case .deletion: Color.danger
        case .context, .hunk, .meta: Color.textTertiary
        }
    }
}
