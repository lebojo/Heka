import SwiftUI

struct OnboardingInstallLink: View {
    let url: URL?

    var body: some View {
        if let url {
            Link("Install…", destination: url)
        }
    }
}
