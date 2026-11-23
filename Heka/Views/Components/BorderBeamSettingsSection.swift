import SwiftUI

struct BorderBeamSettingsSection: View {
    @AppStorage(BorderBeamAppearance.storageKey) private var beam = BorderBeamAppearance()

    var body: some View {
        Section {
            Toggle(isOn: $beam.isEnabled) {
                Text("Border beam")
                Text("A light travels around the message field while the agent works.")
            }
            Picker("Colors", selection: $beam.colorMode) {
                ForEach(BorderBeamColorMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .disabled(!beam.isEnabled)
            ForEach(ConversationAgent.allCases) { agent in
                ColorPicker(agent.title, selection: $beam[colorOf: agent])
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
}
