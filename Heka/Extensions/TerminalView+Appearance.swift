import AppKit
import SwiftTerm

extension TerminalColor {
    var terminalColor: SwiftTerm.Color {
        SwiftTerm.Color(red8: Self.channel(red), green8: Self.channel(green), blue8: Self.channel(blue))
    }

    private static func channel(_ value: Double) -> UInt16 {
        guard value.isFinite else { return 0 }
        return UInt16((min(max(value, 0), 1) * 255).rounded())
    }
}

extension TerminalAppearance {
    var cursorStyle: CursorStyle {
        switch (cursorShape, cursorBlinks) {
        case (.block, true): .blinkBlock
        case (.block, false): .steadyBlock
        case (.underline, true): .blinkUnderline
        case (.underline, false): .steadyUnderline
        case (.bar, true): .blinkBar
        case (.bar, false): .steadyBar
        }
    }
}
