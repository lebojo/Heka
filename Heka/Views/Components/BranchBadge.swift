import SwiftUI

struct BranchBadge: View {
    let branch: GitBranch

    private var foreground: Color { branch.isDetached ? Color.textPrimary : Color.branchForeground }
    private var background: Color { branch.isDetached ? Color.control : Color.branchBackground }

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: branch.symbolName)
                .font(.xxs.weight(.medium))
            Text(branch.name).lineLimit(1).truncationMode(.middle)
        }
        .font(.xs.weight(.medium))
        .foregroundStyle(foreground)
        .padding(.horizontal, Spacing.s).padding(.vertical, Spacing.xxs)
        .background(background, in: Capsule())
        .help(branch.accessibilityLabel)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(branch.accessibilityLabel)
    }
}
