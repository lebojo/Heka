import SwiftUI

struct DropTargetHighlight: View {
    var body: some View {
        RoundedRectangle(cornerRadius: Radius.m)
            .fill(Color.dropTargetFill)
            .strokeBorder(Color.accentColor, lineWidth: Stroke.regular)
            .padding(Spacing.xs)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
