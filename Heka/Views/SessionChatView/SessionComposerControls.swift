import SwiftUI

struct SessionComposerControls: View {
    @Environment(SessionChat.self) private var chat

    let source: SessionChatSource
    let isBusy: Bool
    let isInterruptible: Bool

    private var modelLabel: String {
        String(localized: "Model", comment: "Menu that picks the agent's model in the chat composer")
    }

    private var interruptButton: some View {
        Button { chat.control(Data([27])) } label: {
            Label("Interrupt", systemImage: "stop.fill")
        }
    }

    var body: some View {
        HStack(spacing: Spacing.s) {
            if let command = source.modelPickerCommand {
                Button { Task { _ = await chat.run(command) } } label: {
                    Label(modelLabel, systemImage: "cpu")
                }
                .help("Open the agent's model picker")
                .disabled(isBusy)
            }
            if source == .terminal {
                Button("Ctrl-C") { chat.control(Data([3])) }
                interruptButton
                Button("Return") { chat.control(Data([13])) }
            } else if isInterruptible {
                interruptButton
                    .buttonStyle(.borderedProminent)
            }
        }
        .font(Font.caption)
        .buttonStyle(.bordered).buttonBorderShape(.capsule)
        .controlSize(.small)
    }
}
