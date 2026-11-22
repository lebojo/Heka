import SwiftUI

struct AgentShortcutBar: View {
    let agents: [ConversationAgent]
    let launch: (ConversationAgent) -> Void

    var body: some View {
        HStack(spacing: Spacing.s) {
            ForEach(agents) { agent in
                Button { launch(agent) } label: {
                    Label {
                        Text(agent.title)
                    } icon: {
                        AgentLogo(agent: agent, size: IconSize.xs)
                    }
                }
                .accessibilityLabel("Launch \(agent.title)")
            }
            Spacer(minLength: 0)
        }
        .font(Font.caption)
        .buttonStyle(.bordered).buttonBorderShape(.capsule).controlSize(.small)
        .padding(.horizontal, Spacing.l).padding(.vertical, Spacing.s)
        .frame(maxWidth: .infinity)
        .background(Material.bar)
    }
}
