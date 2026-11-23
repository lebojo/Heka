import SwiftUI

struct SessionPendingMessage: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let message: PendingChatMessage

    private var breathes: Bool { message.state == .sending && !reduceMotion }

    var body: some View {
        VStack(alignment: .trailing, spacing: Spacing.xs) {
            if breathes {
                SessionInputMessage(text: message.text)
                    .phaseAnimator([0.6, 0.3]) { bubble, opacity in
                        bubble.opacity(opacity)
                    } animation: { _ in Motion.breathing }
            } else {
                SessionInputMessage(text: message.text).opacity(0.5)
            }
            switch message.state {
            case .sending:
                Text("Sending…")
                    .font(Font.caption).foregroundStyle(Color.textTertiary)
            case .unconfirmed:
                Label("Not in the conversation yet", systemImage: "exclamationmark.circle")
                    .font(Font.caption).foregroundStyle(Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .accessibilityElement(children: .combine)
    }
}
