import SwiftUI

struct OnboardingSetupPage: View {
    @Environment(InstalledAgents.self) private var installedAgents

    @State private var check = OnboardingSetupCheck()

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
                        OnboardingCheckRow(title: LocalizedStringKey(agent.title), status: agentStatus(agent),
                                           fixURL: installedAgents.agents.contains(agent) ? nil : agent.installURL)
                    }
                }
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
        }
        .task {
            await check.refresh()
            await installedAgents.refresh()
        }
    }

    private func agentStatus(_ agent: ConversationAgent) -> OnboardingCheckStatus {
        installedAgents.agents.contains(agent) ? .ready("Installed") : .problem("Not installed")
    }
}
