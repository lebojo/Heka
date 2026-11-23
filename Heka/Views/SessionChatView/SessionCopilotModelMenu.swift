import SwiftUI

struct SessionCopilotModelMenu: View {
    @Environment(SessionChat.self) private var chat

    let reported: AgentOptions

    private var modelLabel: String {
        String(localized: "Model", comment: "Menu that picks the agent's model in the chat composer")
    }

    private var state: CopilotModelState { chat.shownOptions(reported).copilot ?? CopilotModelState() }

    var body: some View {
        Menu {
            Picker(modelLabel, selection: Bindable(chat)[copilotModel: reported]) {
                ForEach(CopilotModel.choices(including: state.shown)) { Text($0.title).tag($0) }
            }
            .pickerStyle(.inline)
        } label: {
            Text(state.title)
        }
        .help(modelLabel)
        .accessibilityLabel(modelLabel)
        .accessibilityValue(state.title)
    }
}
