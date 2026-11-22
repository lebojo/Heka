import SwiftUI

extension Color {
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color.systemTertiaryLabel

    static let surface = Color.systemSurface
    static let control = Color.systemControl
    static let fill = Color.systemFill
    static let searchFieldFill = fill.opacity(0.6)

    static let popupShadow = Color.black.opacity(0.15)
    static let selectionFill = Color.accentColor.opacity(0.18)
    static let focusedPaneFill = Color.accentColor.opacity(0.12)
    static let dropTargetFill = Color.accentColor.opacity(0.2)

    static let success = Color.green
    static let warning = Color.orange
    static let danger = Color.red
    static let agentWorking = Color.yellow
    static let codeBackground = Color.white
    static let badgeSymbol = Color.white
    static let badgeFill = Color.black.opacity(0.6)
}
