import SwiftUI

struct SessionCommandPopup: View {
    let matches: [SlashCommandMatch]
    let selection: Int
    let accept: (SlashCommand) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(matches.enumerated()), id: \.element.id) { index, match in
                        Button { accept(match.command) } label: {
                            SessionCommandRow(match: match, isSelected: index == selection)
                        }
                        .buttonStyle(.plain)
                        .id(match.id)
                    }
                }
                .padding(Spacing.xs)
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(maxHeight: Dimension.Chat.commandPopupMaxHeight)
            .fixedSize(horizontal: false, vertical: true)
            .onChange(of: selection) { _, index in
                guard matches.indices.contains(index) else { return }
                proxy.scrollTo(matches[index].id)
            }
        }
        .background(Palette.control, in: RoundedRectangle(cornerRadius: Radius.l))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.l)
                .strokeBorder(Palette.textTertiary.opacity(0.4), lineWidth: Stroke.hairline)
        }
        .shadow(color: Palette.popupShadow, radius: Spacing.m, y: Spacing.xs)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Commands")
    }
}

private struct SessionCommandRow: View {
    let match: SlashCommandMatch
    let isSelected: Bool

    private var highlightedName: AttributedString {
        var name = AttributedString(match.command.text)
        for (offset, index) in name.characters.indices.enumerated() where match.matchedOffsets.contains(offset - 1) {
            name[index..<name.characters.index(after: index)].foregroundColor = Palette.accent
            name[index..<name.characters.index(after: index)].inlinePresentationIntent = .stronglyEmphasized
        }
        return name
    }

    var body: some View {
        HStack(spacing: Spacing.m) {
            Text(highlightedName).font(Typography.captionMono)
            if let argument = match.command.argument {
                Text("<\(argument)>").font(Typography.captionMono).foregroundStyle(Palette.textTertiary)
            }
            Spacer(minLength: Spacing.m)
            Text(match.command.summary)
                .font(Typography.caption).foregroundStyle(Palette.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.s)
        .background(isSelected ? Palette.selectionFill : .clear, in: RoundedRectangle(cornerRadius: Radius.m))
        .contentShape(.rect)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
