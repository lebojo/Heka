import SwiftUI

struct OnboardingSetupPage: View {
    @Environment(InstalledAgents.self) private var installedAgents

    @State private var check = OnboardingSetupCheck()
    @State private var hasCheckedAgents = false

    private let gitHubURL = URL(string: "https://cli.github.com")!

    private var gitHubStatus: OnboardingCheckStatus {
        switch check.gitHub {
        case .checking: .checking
        case .missing: .problem("Not installed")
        case .signedOut: .problem("Run gh auth login in a terminal")
        case .signedIn: .ready("Signed in")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            OnboardingPageHeader(title: "Setup Check", subtitle: "Some features rely on tools installed on your Mac. Nothing here is required to continue.")
            Form {
                Section("GitHub") {
                    OnboardingCheckRow(title: "GitHub CLI", status: gitHubStatus, fixURL: check.gitHub == .missing ? gitHubURL : nil)
                }
                Section("Agents") {
                    ForEach(ConversationAgent.allCases) { agent in
                        OnboardingCheckRow(title: LocalizedStringKey(agent.title), status: agentStatus(agent), fixURL: agentFixURL(agent))
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
