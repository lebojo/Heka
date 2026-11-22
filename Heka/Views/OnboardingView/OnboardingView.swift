import SwiftUI

struct OnboardingView: View {
    @State private var step = OnboardingStep.welcome

    var body: some View {
        VStack(spacing: 0) {
            OnboardingPage(step: step)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(Spacing.xxl)
                .id(step)
            Divider()
            OnboardingNavigationBar(step: $step)
        }
        .frame(width: Dimension.Onboarding.width, height: Dimension.Onboarding.height)
    }
}
