import SwiftUI

struct SessionComposerControls: View {
    @Environment(SessionChat.self) private var chat

    let source: SessionChatSource
    let isBusy: Bool

    private var modelLabel: String {
        String(localized: "Model", comment: "Menu that picks the agent's model in the chat composer")
    }

    var body: some View {
        HStack(spacing: Spacing.s) {
            if source == .terminal {
                Button("Ctrl-C") { chat.control(Data([3])) }
            }
            Button { chat.control(Data([27])) } label: {
                Label("Interrupt", systemImage: "stop")
            }
            if let command = source.modelPickerCommand {
                Button { Task { _ = await chat.run(command) } } label: {
                    Label(modelLabel, systemImage: "cpu")
                }
                .help("Open the agent's model picker")
                .disabled(isBusy)
            }
            if source == .terminal {
                Button("Return") { chat.control(Data([13])) }
            }
        }
        .font(Font.caption)
        .buttonStyle(.borderless)
        .foregroundStyle(Color.textSecondary)
    }
}
