import SwiftUI

struct TextPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss

    let preview: TextPreview
    let source: any InspectorSource

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(preview.title).font(.headline).lineLimit(1).truncationMode(.middle)
                Spacer()
                if source.canOpenLocalFiles, let url = preview.url {
                    Button("Open") { source.openLocalFile(url) }
                }
                Button("Close") { dismiss() }.keyboardShortcut(.cancelAction)
            }.padding()
            Divider()
            TextPreviewLines(lines: preview.lines)
        }.previewSheetFrame(.text)
    }
}
