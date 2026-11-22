import SwiftUI

struct TypingIndicator: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Image(systemName: "ellipsis")
            .font(Font.headline)
            .foregroundStyle(Color.textSecondary)
            .symbolEffect(.variableColor.iterative.dimInactiveLayers, options: .repeating, isActive: !reduceMotion)
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.m)
            .background(Color.control, in: Capsule())
            .accessibilityElement()
            .accessibilityLabel("Waiting for a response…")
    }
}
