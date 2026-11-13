import SwiftUI

struct SessionAgentHeader: View {
    @ScaledMetric(relativeTo: .caption) private var logoSize = IconSize.xs

    let agent: ConversationAgent?

    private var name: String {
        agent?.title ?? String(localized: "Agent")
    }

    var body: some View {
        HStack(spacing: Spacing.s) {
            if let agent {
                AgentLogo(agent: agent, size: logoSize)
                    .accessibilityHidden(true)
            }
            Text(verbatim: name)
                .foregroundStyle(Palette.textSecondary)
        }
        .font(Typography.caption)
    }
}
