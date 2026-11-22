import SwiftUI

struct UsageProviderSection: View {
    let provider: UsageProvider
    let state: UsageState
    let now: Date

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: Spacing.l) {
                UsageProviderContent(provider: provider, state: state, now: now)
                if let error = state.error {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.caption).foregroundStyle(Color.warning)
                        .textSelection(.enabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.m)
        } label: {
            HStack(spacing: Spacing.s) {
                AgentLogo(agent: provider.agent, size: IconSize.s).foregroundStyle(Color.textPrimary).accessibilityHidden(true)
                Text(provider.title).font(.headline)
                if let plan = state.usage?.plan {
                    Text(plan).font(.caption).foregroundStyle(Color.textSecondary)
                }
            }
        }
    }
}
