import SwiftUI

struct SearchField: View {
    @Binding var text: String

    let prompt: LocalizedStringKey

    var body: some View {
        HStack(spacing: Spacing.s) {
            Image(systemName: "magnifyingglass").foregroundStyle(Palette.textSecondary)
            TextField(prompt, text: $text)
                .textFieldStyle(.plain)
                .accessibilityLabel(prompt)
            if !text.isEmpty {
                Button { text = "" } label: { Image(systemName: "xmark.circle.fill") }
                    .buttonStyle(.plain).foregroundStyle(Palette.textSecondary).accessibilityLabel("Clear Filter")
            }
        }
        .font(Typography.m)
        .padding(Spacing.m)
        .background(Palette.searchFieldFill, in: RoundedRectangle(cornerRadius: Radius.m))
    }
}
