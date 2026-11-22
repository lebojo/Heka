import SwiftUI

struct TerminalIcon: View {
    let agent: ConversationAgent?

    var body: some View {
        Group {
            if let agent {
                AgentLogo(agent: agent, size: IconSize.s)
            } else {
                Image(systemName: "terminal").font(Font.m).foregroundStyle(Color.textSecondary)
            }
        }
        .accessibilityHidden(true)
    }
}
