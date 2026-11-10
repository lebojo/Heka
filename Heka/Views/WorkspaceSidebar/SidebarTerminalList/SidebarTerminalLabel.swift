import SwiftUI

struct SidebarTerminalLabel: View {
    let name: String
    let summary: TerminalSummary?

    var body: some View {
        HStack(spacing: Spacing.s) {
            TerminalIcon(agent: summary?.agent)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(name).lineLimit(1)
                    .foregroundStyle(summary == nil ? Palette.textSecondary : Palette.textPrimary)
                if let divergentBranch = summary?.divergentBranch {
                    SidebarBranchName(branch: divergentBranch, color: Palette.danger)
                        .help("This terminal is on a different branch from its worktree")
                }
            }
            Spacer(minLength: Spacing.xs)
            if let status = summary?.status {
                AgentStatusBadge(title: status.title, color: status.color)
            } else if let summary {
                Image(systemName: summary.hasExited ? "circle" : "circle.fill")
                    .font(Typography.statusDot).foregroundStyle(summary.hasExited ? Palette.textSecondary : Palette.success)
                    .accessibilityLabel(summary.hasExited ? "Session ended" : "Terminal open")
            } else {
                Image(systemName: "moon").font(Typography.caption).foregroundStyle(Palette.textSecondary)
                    .accessibilityLabel("Idle terminal")
            }
        }
        .help(summary == nil ? String(localized: "\(name) — idle, click to open it") : name)
    }
}
