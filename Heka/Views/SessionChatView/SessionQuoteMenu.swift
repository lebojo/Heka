import SwiftUI

struct SessionQuoteMenu: ViewModifier {
    let text: String
    let quote: () -> Void

    func body(content: Content) -> some View {
        #if os(macOS)
        content
            .contextMenu {
                Button("Copy", systemImage: "doc.on.doc") { PlatformClipboard.copy(text) }
                Button("Quote", systemImage: "text.quote", action: quote)
            }
        #else
        content
        #endif
    }
}
