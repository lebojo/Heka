import SwiftUI

extension SessionMessage.ToolState {
    var tint: Color { self == .failed ? Color.danger : Color.textSecondary }
}
