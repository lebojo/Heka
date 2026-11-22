import SwiftUI

struct OnboardingCheckRow: View {
    let title: LocalizedStringKey
    let status: OnboardingCheckStatus
    let fixURL: URL?

    var body: some View {
        LabeledContent {
            HStack {
                OnboardingCheckStatusLabel(status: status)
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
