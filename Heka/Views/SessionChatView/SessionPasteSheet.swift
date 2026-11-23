import SwiftUI

struct SessionPasteSheet: View {
    @Environment(\.dismiss) private var dismiss

    let paste: ChatPaste

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(paste.token).font(.headline).lineLimit(1)
                Spacer()
                Button("Close") { dismiss() }.keyboardShortcut(.cancelAction)
            }
            .padding()
            Divider()
            ScrollView {
                SessionMarkdown(text: paste.markdown)
                    .padding()
            }
            .background(Color.surface)
        }
        .previewSheetFrame(.text)
    }
}
