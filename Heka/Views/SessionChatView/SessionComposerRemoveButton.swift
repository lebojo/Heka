import SwiftUI

struct SessionComposerRemoveButton: View {
    let title: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark.circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color.badgeSymbol, Color.badgeFill)
        }
        .buttonStyle(.plain)
        .padding(Spacing.xxs)
        .accessibilityLabel(title)
        .help(title)
    }
}
