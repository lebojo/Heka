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

    @ViewBuilder private var pickers: some View {
        Picker(selection: model) {
            ForEach(source.models) { Text($0.title).tag($0) }
        } label: {
            Text(modelLabel)
        }
        .help(modelLabel)
        Picker(selection: effort) {
            ForEach(AgentEffort.allCases) { level in
                Text(level.title).tag(level).disabled(!efforts.contains(level))
            }
        } label: {
            Text(effortLabel)
        }
        .help(effortLabel)
        .disabled(efforts.isEmpty)
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.s) { pickers }
            VStack(alignment: .leading, spacing: Spacing.xs) { pickers }
        }
        .pickerStyle(.menu)
        .labelsHidden()
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
