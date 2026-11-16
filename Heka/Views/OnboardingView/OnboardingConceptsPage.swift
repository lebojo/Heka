import SwiftUI

struct OnboardingConceptsPage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            OnboardingPageHeader(title: "How Heka Works", subtitle: "A few ideas to find your way around.")
            OnboardingFeatureRow(systemImage: "folder", title: "Folders, projects and worktrees",
                                 detail: "Group projects in virtual folders. Each project holds Git worktrees, and each worktree holds its terminals.")
            OnboardingFeatureRow(systemImage: "text.bubble", title: "Terminal and chat modes",
                                 detail: "Follow an agent in its raw terminal, or switch to a chat view of the same session.")
            OnboardingFeatureRow(systemImage: "sidebar.right", title: "Inspector",
                                 detail: "Browse Files, Agents, Git changes and Checks for the selected worktree.")
            OnboardingFeatureRow(systemImage: "iphone", title: "Agent CLI and Mobile Control",
                                 detail: "Let agents drive Heka with the heka command, and follow them from your iPhone.")
        }
    }
}
