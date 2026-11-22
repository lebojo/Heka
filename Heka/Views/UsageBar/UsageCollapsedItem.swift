import SwiftUI

struct UsageCollapsedItem: View {
    let provider: UsageProvider
    let state: UsageState

    private var window: UsageWindow? { state.usage?.headline }

    var body: some View {
        HStack(spacing: Spacing.xs) {
            AgentLogo(agent: provider.agent, size: IconSize.xs).foregroundStyle(Color.textPrimary).accessibilityHidden(true)
            if let window {
                Text(window.percentText)
                    .monospacedDigit()
                    .foregroundStyle(window.level == .comfortable ? Color.textSecondary : window.level.tint)
            } else {
                Text("—").foregroundStyle(Color.textSecondary)
            }
            if state.error != nil {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Color.warning)
                    .help(state.error ?? "")
            }
        }
        .font(.s.weight(.medium))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(window.map { "\(provider.title), " + String(localized: "\($0.kind.title): \($0.percentText) used") } ?? "\(provider.title), " + String(localized: "usage unavailable"))
    }
}
