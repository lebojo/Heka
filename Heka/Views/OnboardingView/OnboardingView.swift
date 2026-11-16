import SwiftUI

struct OnboardingView: View {
    @State private var step = OnboardingStep.welcome

    @ViewBuilder private var page: some View {
        switch step {
        case .welcome: OnboardingWelcomePage()
        case .concepts: OnboardingConceptsPage()
        case .setup: OnboardingSetupPage()
        case .project: OnboardingProjectPage()
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            page
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(24)
                .id(step)
            Divider()
            OnboardingNavigationBar(step: $step)
        }
        .frame(width: Dimension.Onboarding.width, height: Dimension.Onboarding.height)
    }
}
