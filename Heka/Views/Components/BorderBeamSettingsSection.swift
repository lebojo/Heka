import SwiftUI

struct BorderBeamSettingsSection: View {
    @AppStorage(BorderBeamAppearance.storageKey) private var beam = BorderBeamAppearance()

    @Environment(\.self) private var environment

    var body: some View {
        Section {
            Toggle(isOn: $beam.isEnabled) {
                Text("Border beam")
                Text("A light travels around the message field while the agent works.")
            }
            ForEach(ConversationAgent.allCases) { agent in
                ColorPicker(agent.title, selection: colorBinding(for: agent))
                    .disabled(!beam.isEnabled)
            }
            HStack {
                Spacer()
                Button("Reset Colors") { beam.resetColors() }
                    .disabled(!beam.hasCustomColors)
            }
        } header: {
            Text("Border Beam")
        }
    }

    private func colorBinding(for agent: ConversationAgent) -> Binding<Color> {
        Binding {
            beam.color(for: agent).color
        } set: { color in
            beam.setColor(HexColor(color, in: environment), for: agent)
        }
    }
}
