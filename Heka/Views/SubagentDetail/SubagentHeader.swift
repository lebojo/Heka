import SwiftUI

struct SubagentHeader: View {
    let store: WorkspaceStore
    let context: TerminalContext
    let subagent: Subagent

    var body: some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: "shippingbox").foregroundStyle(Color.textSecondary)
            Text(context.project.name).fontWeight(.medium)
            Image(systemName: "chevron.right").font(Font.xxs).foregroundStyle(Color.textTertiary)
            Button { store.selection = context.terminal.id } label: {
                Label(context.terminal.name, systemImage: "terminal")
            }
            .buttonStyle(.borderless).foregroundStyle(Color.textSecondary)
            .help("Show the parent terminal")
            Image(systemName: "chevron.right").font(Font.xxs).foregroundStyle(Color.textTertiary)
            TerminalIcon(agent: .claude)
            Text(subagent.title).fontWeight(.medium).truncationMode(.tail)
            Spacer(minLength: Spacing.l)
            AgentStatusBadge(title: subagent.status.title, color: subagent.status.color)
        }
        .font(Font.m).lineLimit(1).padding(.horizontal, Spacing.xl).frame(height: Dimension.Detail.headerHeight)
    }
}
