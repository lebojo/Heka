#if os(macOS)
import SwiftUI

struct UsageProviderContent: View {
    let provider: UsageProvider
    let state: UsageState
    let now: Date

    var body: some View {
        switch state {
        case .loading:
            HStack(spacing: Spacing.m) {
                ProgressView().controlSize(.small)
                Text("Loading…").font(.callout).foregroundStyle(Color.textSecondary)
            }
        case .signedOut:
            HStack(alignment: .center, spacing: Spacing.l) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Not Signed In").font(.label)
                    Text(provider.signInHint).font(.caption).foregroundStyle(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                UsageSignInButton(provider: provider)
            }
        case .loaded(let usage), .failed(_, .some(let usage)):
            if usage.windows.isEmpty {
                Text("No limits reported for this account.").font(.callout).foregroundStyle(Color.textSecondary)
            }
            ForEach(usage.windows) { window in
                UsageWindowRow(window: window, now: now)
            }
            if let spend = usage.spend {
                UsageSpendRow(spend: spend)
            }
        case .failed(_, nil):
            EmptyView()
        }
    }
}
#endif
