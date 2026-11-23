import SwiftUI

struct OnboardingCheckStatusLabel: View {
    let status: OnboardingCheckStatus

    var body: some View {
        switch status {
        case .checking:
            ProgressView().controlSize(.small)
                .accessibilityLabel("Checking")
        case .working(let text):
            HStack(spacing: Spacing.s) {
                ProgressView().controlSize(.small)
                Text(text)
            }
            .foregroundStyle(Color.textSecondary)
        case .ready(let text):
            Label(text, systemImage: "checkmark.circle.fill")
                .foregroundStyle(Color.success)
        case .problem(let text):
            Label(text, systemImage: "exclamationmark.circle")
                .foregroundStyle(Color.textSecondary)
        }
    }
}
