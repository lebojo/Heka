import SwiftUI

struct OnboardingWelcomePage: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: Dimension.Onboarding.appIconSize, height: Dimension.Onboarding.appIconSize)
                .accessibilityHidden(true)
            Text("Welcome to Heka")
                .font(.largeTitle)
                .bold()
                .accessibilityAddTraits(.isHeader)
            Text("Heka organizes your projects and worktrees, and runs your coding agents side by side in terminals or chats.")
                .font(.title3)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
