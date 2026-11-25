import SwiftUI

struct OnboardingSetupPage: View {
    @Environment(InstalledAgents.self) private var installedAgents

    @State private var check = OnboardingSetupCheck()
    @State private var hasCheckedAgents = false

    private let gitHubURL = URL(string: "https://cli.github.com")!

    private var gitHubStatus: OnboardingCheckStatus {
        if check.installation == .running { return .working("Installing…") }
        switch check.gitHub {
        case .checking: return .checking
        case .missing: return check.installation.failure == nil ? .problem("Not installed") : .problem("Installation failed")
        case .signedOut: return .problem("Run gh auth login in a terminal")
        case .signedIn: return .ready("Signed in")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            OnboardingPageHeader(title: "Setup Check", subtitle: "Some features rely on tools installed on your Mac. Nothing here is required to continue.")
            Form {
                Section("GitHub") {
                    OnboardingCheckRow(title: "GitHub CLI", status: gitHubStatus,
                                       accessory: OnboardingGitHubInstallActions(check: check, webURL: gitHubURL))
                    if let failure = check.installation.failure, check.gitHub == .missing {
                        Text(failure)
                            .font(.caption)
                            .foregroundStyle(Color.danger)
                            .lineLimit(4)
                            .textSelection(.enabled)
                    }
                }
                Section("Agents") {
                    ForEach(ConversationAgent.allCases) { agent in
                        OnboardingCheckRow(title: LocalizedStringKey(agent.title), status: agentStatus(agent),
                                           accessory: OnboardingInstallLink(url: agentFixURL(agent)))
                    }
                }
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
        }
        .task { await check.refresh() }
        .task(checkAgents)
    }

    private func checkAgents() async {
        await installedAgents.reload()
        hasCheckedAgents = true
    }

    private func agentStatus(_ agent: ConversationAgent) -> OnboardingCheckStatus {
        guard hasCheckedAgents else { return .checking }
        return installedAgents.agents.contains(agent) ? .ready("Installed") : .problem("Not installed")
    }

    private func agentFixURL(_ agent: ConversationAgent) -> URL? {
        hasCheckedAgents && !installedAgents.agents.contains(agent) ? agent.installURL : nil
    }
}
