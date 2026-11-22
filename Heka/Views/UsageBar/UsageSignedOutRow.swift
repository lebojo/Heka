import SwiftUI

struct UsageSignedOutRow: View {
    let isWaiting: Bool
    let showDetails: () -> Void

    var body: some View {
        HStack(spacing: Spacing.s) {
            Image(systemName: "gauge.with.dots.needle.33percent")
            Text(isWaiting ? "Waiting for sign-in…" : "Agent Usage")
            Spacer(minLength: Spacing.xs)
            if isWaiting { ProgressView().controlSize(.mini) }
            else { Button("Sign In…", action: showDetails).buttonStyle(.link) }
        }
        .font(.s).foregroundStyle(Color.textSecondary)
        .padding(.horizontal, Spacing.l).padding(.vertical, Spacing.m)
    }
}
