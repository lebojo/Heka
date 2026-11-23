import SwiftUI

struct FloatingTerminalPane: View {
    @Environment(FloatingTerminalStore.self) private var floating

    let id: UUID
    let isFocused: Bool
    let isSplit: Bool

    private var session: TerminalSession? { floating.session(id) }

    var body: some View {
        VStack(spacing: 0) {
            if isSplit {
                TerminalPaneHeader(title: floating.title(of: id), branch: session?.branch, isFocused: isFocused) { floating.close(id) }
                    .onTapGesture { floating.focus(id) }
                Divider()
            }
            if let session {
                LocalSessionContent(session: session, isFocused: isFocused) { floating.focus(id) }
                SessionEndedBar(session: session, accessory: Button("Close") { floating.close(id) }) { floating.reopen(id) }
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task { floating.startSession(id) }
    }
}
