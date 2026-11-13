import SwiftUI

struct MobileSessionHeader: View {
    let project: String
    let worktree: String
    let agent: ConversationAgent?

    var body: some View {
        HStack(spacing: Spacing.s) {
            Group {
                Label(project, systemImage: "shippingbox")
                Image(systemName: "chevron.right")
                Label(worktree, systemImage: "arrow.triangle.branch")
            }
            .foregroundStyle(Palette.textSecondary)
            Spacer(minLength: Spacing.s)
            if let agent {
                AgentLogo(agent: agent, size: IconSize.m)
                    .accessibilityLabel(agent.title)
            }
        }
        .font(Typography.caption).lineLimit(1)
        .padding(.horizontal, Spacing.l).padding(.vertical, Spacing.m)
    }
}
