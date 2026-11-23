import SwiftUI

struct SessionClaudeOptions: View {
    @Environment(SessionChat.self) private var chat

    let source: SessionChatSource
    let reported: AgentOptions

    private var modelLabel: String {
        String(localized: "Model", comment: "Menu that picks the agent's model in the chat composer")
    }

    private var effortLabel: String {
        String(localized: "Reasoning Effort", comment: "Menu that picks how much the agent reasons before answering")
    }

    private var shown: AgentOptions { chat.shownOptions(reported) }

    private var efforts: [AgentEffort] { source.efforts(for: shown.model) }

    var body: some View {
        Menu {
            Picker(modelLabel, selection: Bindable(chat)[model: reported]) {
                ForEach(source.models) { Text($0.title).tag($0) }
            }
            .pickerStyle(.inline)
        } label: {
            Text(shown.model.title)
        }
        .help(modelLabel)
        .accessibilityLabel(modelLabel)
        .accessibilityValue(shown.model.title)
        Menu {
            Picker(effortLabel, selection: Bindable(chat)[effort: reported]) {
                ForEach(AgentEffort.allCases) { level in
                    Text(level.title).tag(level).disabled(!efforts.contains(level))
                }
            }
            .pickerStyle(.inline)
        } label: {
            Text(shown.effort.title)
        }
        .help(effortLabel)
        .accessibilityLabel(effortLabel)
        .accessibilityValue(shown.effort.title)
        .disabled(efforts.isEmpty)
    }
}
