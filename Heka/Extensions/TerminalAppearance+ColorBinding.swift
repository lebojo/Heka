#if os(macOS)
import SwiftUI

extension TerminalAppearance {
    subscript(color keyPath: WritableKeyPath<TerminalPalette, TerminalColor>) -> Color {
        get { palette?[keyPath: keyPath].color ?? .clear }
        set { setColor(TerminalColor(newValue), at: keyPath) }
    }
}
#endif
