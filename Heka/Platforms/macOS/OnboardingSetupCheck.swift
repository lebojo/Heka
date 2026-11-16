import Foundation
import Observation

@MainActor @Observable final class OnboardingSetupCheck {
    enum GitHubStatus: Equatable, Sendable {
        case checking, missing, signedOut, signedIn
    }

    private(set) var gitHub: GitHubStatus = .checking

    func refresh() async {
        gitHub = .checking
        gitHub = await Self.detectGitHub()
    }

    @concurrent private static func detectGitHub() async -> GitHubStatus {
        guard let gh = ReadCommand.executable("gh") else { return .missing }
        do {
            _ = try await ReadCommand.run(gh, ["auth", "status"], at: NSHomeDirectory(), timeout: 10, limit: 65_536)
            return .signedIn
        } catch {
            return .signedOut
        }
    }
}
