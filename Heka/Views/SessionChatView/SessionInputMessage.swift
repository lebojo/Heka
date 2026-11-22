import SwiftUI

struct SessionInputMessage: View {
    let text: String

    var body: some View {
        HStack(alignment: .top) {
            Spacer(minLength: Spacing.xxl)
            Text(verbatim: text)
                .font(Font.chatInput).textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .padding(Spacing.l)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: Radius.l))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("You")
                .accessibilityValue(text)
        }
    }
}
