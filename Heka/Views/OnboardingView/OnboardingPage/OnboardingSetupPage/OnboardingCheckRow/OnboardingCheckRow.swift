import SwiftUI

struct OnboardingCheckRow<Accessory: View>: View {
    let title: LocalizedStringKey
    let status: OnboardingCheckStatus
    let accessory: Accessory

    var body: some View {
        LabeledContent {
            HStack {
                OnboardingCheckStatusLabel(status: status)
                accessory
            }
        } label: {
            Text(title)
        }
        .accessibilityElement(children: .combine)
    }
}
