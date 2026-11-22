import SwiftUI

struct SidebarStatusHeader: View {
    let status: AgentStatus
    let count: Int

    var body: some View {
        HStack(spacing: Spacing.s) {
            Circle().fill(status.color)
                .frame(width: Dimension.Badge.statusDotSize, height: Dimension.Badge.statusDotSize)
            Text(status.title)
            Spacer(minLength: Spacing.xs)
            Text(count, format: .number).monospacedDigit()
        }
        .font(Font.caption.weight(.medium))
        .foregroundStyle(Color.textSecondary)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(status.title), \(count) terminals")
        .accessibilityAddTraits(.isHeader)
    }
}
