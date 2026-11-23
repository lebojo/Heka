import SwiftUI

struct SessionQuotable: ViewModifier {
    @Environment(SessionChat.self) private var chat: SessionChat?

    @State private var isQuoting = false
    @State private var isHovered = false

    let message: SessionMessage
    let agent: ConversationAgent?

    private var showsQuoteButton: Bool {
        #if os(macOS)
        isHovered || isQuoting
        #else
        true
        #endif
    }

    private var hasQuoteButton: Bool {
        #if os(macOS)
        message.kind == .assistant
        #else
        true
        #endif
    }

    func body(content: Content) -> some View {
        if let chat, agent != nil, message.isQuotable {
            content
                .overlay(alignment: .topTrailing) {
                    if hasQuoteButton {
                        Button("Quote", systemImage: "text.quote") { isQuoting = true }
                            .labelStyle(.iconOnly)
                            .buttonStyle(.borderless)
                            .font(Font.caption)
                            .foregroundStyle(Color.textSecondary)
                            .help("Quote")
                            .opacity(showsQuoteButton ? 1 : 0)
                    }
                }
                .modifier(SessionQuoteMenu(text: message.text) { isQuoting = true })
                .popover(isPresented: $isQuoting, attachmentAnchor: .point(.topTrailing)) {
                    SessionQuotePopover(message: message, terminal: chat.terminal)
                        .presentationCompactAdaptation(.popover)
                }
                .onHover { isHovered = $0 }
        } else {
            content
        }
    }
}

extension View {
    func quotable(_ message: SessionMessage, agent: ConversationAgent?) -> some View {
        modifier(SessionQuotable(message: message, agent: agent))
    }
}
