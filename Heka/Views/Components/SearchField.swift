import SwiftUI

struct SearchField: View {
    @Binding var text: String

    let prompt: LocalizedStringKey

    var body: some View {
        HStack(spacing: Spacing.s) {
            Image(systemName: "magnifyingglass").foregroundStyle(Color.textSecondary)
            TextField(prompt, text: $text)
                .textFieldStyle(.plain)
                .accessibilityLabel(prompt)
            if !text.isEmpty {
                Button { text = "" } label: { Image(systemName: "xmark.circle.fill") }
                    .buttonStyle(.plain).foregroundStyle(Color.textSecondary).accessibilityLabel("Clear Filter")
            }
        }
        .font(.m)
        .padding(Spacing.m)
        .background(Color.searchFieldFill, in: RoundedRectangle(cornerRadius: Radius.m))
    }
}
