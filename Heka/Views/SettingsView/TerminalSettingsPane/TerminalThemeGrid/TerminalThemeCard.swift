import SwiftUI

struct TerminalThemeCard: View {
    let appearance: TerminalAppearance
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("❯ ").foregroundStyle(appearance.ansi[2]) + Text("ls").foregroundStyle(appearance.foreground)
                HStack(spacing: Spacing.xs) {
                    ForEach(1..<7) { index in
                        Circle().fill(appearance.ansi[index])
                            .frame(width: Dimension.Settings.swatchSize, height: Dimension.Settings.swatchSize)
                    }
                }
            }
            .font(.code)
            .frame(maxWidth: .infinity, minHeight: Dimension.Settings.themeSampleHeight, alignment: .leading)
            .padding(.horizontal, Spacing.m)
            .background(appearance.background, in: RoundedRectangle(cornerRadius: Radius.m))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.m)
                    .strokeBorder(isSelected ? Color.accentColor : Color.fill, lineWidth: isSelected ? Stroke.regular : 1)
            }
            Text(appearance.theme.title)
                .font(.s)
                .foregroundStyle(isSelected ? Color.textPrimary : Color.textSecondary)
                .lineLimit(1)
        }
        .contentShape(Rectangle())
    }
}
