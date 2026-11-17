import SwiftUI

enum OnboardingCheckStatus: Equatable {
    case checking
    case ready(LocalizedStringKey)
    case problem(LocalizedStringKey)
}

struct OnboardingCheckRow: View {
    let title: LocalizedStringKey
    let status: OnboardingCheckStatus
    let fixURL: URL?

    @ViewBuilder private var statusView: some View {
        switch status {
        case .checking:
            ProgressView().controlSize(.small)
                .accessibilityLabel("Checking")
        case .ready(let text):
            Label(text, systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .problem(let text):
            Label(text, systemImage: "exclamationmark.circle")
                .foregroundStyle(.secondary)
        }
    }

    var body: some View {
        LabeledContent {
            HStack {
                statusView
                if let fixURL {
                    Link("Install…", destination: fixURL)
                }
            }
        } label: {
            Text(title)
        }
        .accessibilityElement(children: .combine)
    }
}
