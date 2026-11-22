import SwiftUI

struct SessionCommandRow: View {
    let match: SlashCommandMatch
    let isSelected: Bool

    private var highlightedName: AttributedString {
        var name = AttributedString(match.command.text)
        for (offset, index) in name.characters.indices.enumerated() where match.matchedOffsets.contains(offset - 1) {
            name[index..<name.characters.index(after: index)].foregroundColor = Color.accentColor
            name[index..<name.characters.index(after: index)].inlinePresentationIntent = .stronglyEmphasized
        }
        return name
    }

    var body: some View {
        HStack(spacing: Spacing.m) {
            Text(highlightedName).font(Font.captionMono)
            if let argument = match.command.argument {
                Text("<\(argument)>").font(Font.captionMono).foregroundStyle(Color.textTertiary)
            }
            Spacer(minLength: Spacing.m)
            Text(match.command.summary)
                .font(Font.caption).foregroundStyle(Color.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.s)
        .background(isSelected ? Color.selectionFill : .clear, in: RoundedRectangle(cornerRadius: Radius.m))
        .contentShape(.rect)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
