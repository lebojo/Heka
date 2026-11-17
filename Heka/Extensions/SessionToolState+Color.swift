import SwiftUI

extension SessionMessage.ToolState {
    var tint: Color { self == .failed ? Palette.danger : Palette.textSecondary }
}
