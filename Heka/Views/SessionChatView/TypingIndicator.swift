import SwiftUI

struct TypingIndicatorSlot: View {
    let isVisible: Bool

    var body: some View {
        VStack(alignment: .leading) {
            if isVisible {
                TypingIndicator()
                    .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .leading)))
            }
        }
        .animation(.smooth, value: isVisible)
    }
}

struct TypingIndicator: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Image(systemName: "ellipsis")
            .font(Typography.headline)
            .foregroundStyle(Palette.textSecondary)
            .symbolEffect(.variableColor.iterative.dimInactiveLayers, options: .repeating, isActive: !reduceMotion)
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.m)
            .background(Palette.control, in: Capsule())
            .accessibilityElement()
            .accessibilityLabel("Waiting for a response…")
    }
}
