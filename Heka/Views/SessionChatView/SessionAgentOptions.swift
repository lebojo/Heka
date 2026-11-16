import SwiftUI

struct SessionAgentOptions: View {
    @State private var requested: AgentOptions?

    let source: SessionChatSource
    let reported: AgentOptions
    let isBusy: Bool
    let run: (AgentCommand) async -> Bool

    private var modelLabel: String {
        String(localized: "Model", comment: "Menu that picks the agent's model in the chat composer")
    }

    private var effortLabel: String {
        String(localized: "Reasoning Effort", comment: "Menu that picks how much the agent reasons before answering")
    }

    private var shown: AgentOptions { requested ?? reported }

    private var efforts: [AgentEffort] { source.efforts(for: shown.model) }

    private var model: Binding<AgentModel> {
        Binding { shown.model } set: { model in
            request(shown.switching(to: model, efforts: source.efforts(for: model)), with: model.command)
        }
    }

    private var effort: Binding<AgentEffort> {
        Binding { shown.effort } set: { effort in
            var options = shown
            options.effort = effort
            request(options, with: effort.command)
        }
    }

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Menu {
                Picker(modelLabel, selection: model) {
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
                Picker(effortLabel, selection: effort) {
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
        .compactMenuStyle()
        .font(Typography.caption)
        .disabled(isBusy)
        .onChange(of: reported) { requested = nil }
    }

    private func request(_ options: AgentOptions, with command: AgentCommand) {
        requested = options
        Task {
            if await !run(command), requested == options { requested = nil }
        }
    }
}
