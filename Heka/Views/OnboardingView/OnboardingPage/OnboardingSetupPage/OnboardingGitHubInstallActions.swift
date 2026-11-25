import SwiftUI

struct OnboardingGitHubInstallActions: View {
    let check: OnboardingSetupCheck
    let webURL: URL

    var body: some View {
        if check.canInstallWithHomebrew {
            Button("Install with Homebrew") {
                Task { await check.installGitHub() }
            }
            .help("Runs brew install gh")
        }
        if check.offersWebInstall {
            Link("Install…", destination: webURL)
        }
    }
}
