import SwiftUI

struct TerminalPaneHeader: View {
    let title: String
    let branch: GitBranch?
    let isFocused: Bool
    let close: () -> Void

    var body: some View {
        HStack(spacing: Spacing.s) {
            Image(systemName: "terminal").foregroundStyle(isFocused ? Color.accentColor : Color.textSecondary)
            Text(title).lineLimit(1)
                .foregroundStyle(isFocused ? Color.textPrimary : Color.textSecondary)
            if let branch {
                BranchBadge(branch: branch).frame(maxWidth: Dimension.Badge.sidebarMaxWidth)
            }
            Spacer(minLength: Spacing.xs)
            Button(action: close) { Image(systemName: "xmark") }
                .buttonStyle(.borderless).help("Close This Pane")
                .accessibilityLabel("Close terminal \(title)")
        }
        .font(Font.s).padding(.horizontal, Spacing.l).frame(height: Dimension.Detail.paneTitleHeight)
        .background(isFocused ? Color.focusedPaneFill : .clear)
        .contentShape(Rectangle())
    }
}
