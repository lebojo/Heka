import SwiftUI

struct OnboardingPage: View {
    let step: OnboardingStep

    var body: some View {
        switch step {
        case .welcome: OnboardingWelcomePage()
        case .concepts: OnboardingConceptsPage()
        case .setup: OnboardingSetupPage()
        case .project: OnboardingProjectPage()
        }
    }
}
