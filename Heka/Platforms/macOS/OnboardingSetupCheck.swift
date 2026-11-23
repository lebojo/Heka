import Foundation
import Observation

@MainActor @Observable final class OnboardingSetupCheck {
    enum GitHubStatus: Equatable, Sendable {
        case checking, missing, signedOut, signedIn
    }

    enum Installation: Equatable, Sendable {
        case idle, running, failed(String)

        var failure: String? {
            if case .failed(let message) = self { message } else { nil }
        }
    }

    private(set) var gitHub: GitHubStatus = .checking
    private(set) var homebrew: URL?
    private(set) var installation: Installation = .idle

    var canInstallWithHomebrew: Bool { gitHub == .missing && homebrew != nil && installation != .running }
    var offersWebInstall: Bool { gitHub == .missing && (homebrew == nil || installation.failure != nil) }

    func refresh() async {
        gitHub = .checking
        homebrew = await Self.detectHomebrew()
        gitHub = await Self.detectGitHub()
    }

    func installGitHub() async {
        guard let homebrew, canInstallWithHomebrew else { return }
        installation = .running
        do {
            _ = try await CommandRunner.output(homebrew, ["install", "gh"], at: NSHomeDirectory(), timeout: 1800,
                                               limit: 65_536, readOnly: false, overflow: .discard)
            installation = .idle
        } catch {
            installation = .failed(error.localizedDescription)
        }
        await refresh()
    }

    @concurrent private static func detectHomebrew() async -> URL? {
        ReadCommand.executable("brew")
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
