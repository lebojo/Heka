import SwiftUI

struct SessionCommandPopup: View {
    let matches: [SlashCommandMatch]
    let selection: Int
    let accept: (SlashCommand) -> Void

    private var selectedID: String? {
        matches.indices.contains(selection) ? matches[selection].id : nil
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(matches) { match in
                        Button { accept(match.command) } label: {
                            SessionCommandRow(match: match, isSelected: match.id == selectedID)
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
        .background(Color.control, in: RoundedRectangle(cornerRadius: Radius.l))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.l)
                .strokeBorder(Color.textTertiary.opacity(0.4), lineWidth: Stroke.hairline)
        }
        .shadow(color: Color.popupShadow, radius: Spacing.m, y: Spacing.xs)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Commands")
    }
}
