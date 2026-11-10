import SwiftUI

struct WorktreeLaunchPicker: View {
    @Binding var launch: AgentLaunch

    let agents: [ConversationAgent]

    var body: some View {
        HStack(spacing: Spacing.s) {
            Toggle("Start with", isOn: $launch.onNewWorktree)
            Picker("Agent", selection: $launch.agent) {
                ForEach(agents) { agent in
                    Text(agent.title).tag(agent)
                }
            }
            .labelsHidden().fixedSize()
            .disabled(!launch.onNewWorktree)
        }
    }
}
