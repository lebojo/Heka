import SwiftUI

struct SidebarSubagentRow: View {
    let subagent: Subagent

    var body: some View {
        HStack(spacing: Spacing.s) {
            TerminalIcon(agent: .claude)
            Text(subagent.title).lineLimit(1).truncationMode(.tail)
            Spacer(minLength: Spacing.xs)
            AgentStatusBadge(title: subagent.status.title, color: subagent.status.color)
        }
        .tag(subagent.id)
        #if os(iOS)
        .selectionDisabled()
        #endif
        .help(subagent.title)
        .accessibilityElement(children: .combine)
    }
}
