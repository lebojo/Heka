import SwiftUI

struct TextPreviewLines: View {
    let lines: [TextPreviewLine]

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(lines) { line in
                    Text(line.displayText).fixedSize()
                }
            }
            .font(.code)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding()
        }
        .background(Color.surface)
    }
}
