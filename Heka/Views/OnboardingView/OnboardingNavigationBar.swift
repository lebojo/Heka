import SwiftUI

struct OnboardingNavigationBar: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var step: OnboardingStep

    var body: some View {
        HStack {
            Button("Skip") { dismiss() }
                .keyboardShortcut(.cancelAction)
                .accessibilityHint("Closes the introduction. You can replay it from the Help menu.")
            Spacer()
            Text("Step \(step.rawValue + 1) of \(OnboardingStep.allCases.count)")
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
            if let previous = step.previous {
                Button("Back") { step = previous }
                    .keyboardShortcut("[", modifiers: .command)
            }
            if let next = step.next {
                Button("Continue") { step = next }
                    .keyboardShortcut(.defaultAction)
            } else {
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
    }
}
