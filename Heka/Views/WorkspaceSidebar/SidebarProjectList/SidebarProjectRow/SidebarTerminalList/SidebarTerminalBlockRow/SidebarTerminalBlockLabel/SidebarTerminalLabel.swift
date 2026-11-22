import SwiftUI

struct SidebarTerminalLabel: View {
    let name: String
    let summary: TerminalSummary?

    var body: some View {
        HStack(spacing: Spacing.s) {
            TerminalIcon(agent: summary?.agent)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(name).lineLimit(1)
                    .foregroundStyle(summary == nil ? Color.textSecondary : Color.textPrimary)
                if let divergentBranch = summary?.divergentBranch {
                    SidebarBranchName(branch: divergentBranch, color: Color.danger)
                        .help("This terminal is on a different branch from its worktree")
                }
            }
            Spacer(minLength: Spacing.xs)
            if let status = summary?.status {
                AgentStatusBadge(title: status.title, color: status.color)
            } else if let summary {
                Image(systemName: summary.hasExited ? "circle" : "circle.fill")
                    .font(Font.statusDot).foregroundStyle(summary.hasExited ? Color.textSecondary : Color.success)
                    .accessibilityLabel(summary.hasExited ? "Session ended" : "Terminal open")
            } else {
                Image(systemName: "moon").font(Font.caption).foregroundStyle(Color.textSecondary)
                    .accessibilityLabel("Idle terminal")
            }
        }
        .help(summary == nil ? String(localized: "\(name) — idle, click to open it") : name)
    }
}
