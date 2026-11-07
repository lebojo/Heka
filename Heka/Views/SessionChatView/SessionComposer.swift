import SwiftUI

struct SessionComposer: View {
    @FocusState private var isFocused: Bool

    @Binding var draft: String

    let source: SessionChatSource
    let sending: Bool
    let isEnabled: Bool
    let submit: () -> Void
    let control: (Data) -> Void

    private var prompt: String {
        source.agent.map { String(localized: "Message \($0.title)") } ?? String(localized: "Message or command")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            TextField(prompt, text: $draft, axis: .vertical)
                .font(.body)
                .autocorrectionDisabled()
                .commandInputTraits()
                .submitsChatMessage(perform: submit)
                .lineLimit(3...8).textFieldStyle(.plain)
                .focused($isFocused)
                .accessibilityLabel(prompt)
                .padding(.horizontal, Spacing.xs)

            HStack(spacing: Spacing.m) {
                SessionComposerControls(source: source, control: control)
                Spacer(minLength: Spacing.s)
                #if os(macOS)
                Text("⌥Return for a new line")
                    .font(Typography.caption).foregroundStyle(Palette.textSecondary)
                #endif
                Button(action: submit) {
                    Group {
                        if sending { ProgressView().controlSize(.small) }
                        else { Image(systemName: "arrow.up").font(Typography.headline) }
                    }
                    .frame(minWidth: Dimension.Chat.actionSize, minHeight: Dimension.Chat.actionSize)
                    .contentShape(.circle)
                }
                .buttonStyle(.borderedProminent).buttonBorderShape(.circle)
                .keyboardShortcut(.return, modifiers: .command)
                .accessibilityLabel("Send to Session")
                .help("Send to Session")
                .disabled(sending || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(Spacing.l)
        .background(Palette.control, in: RoundedRectangle(cornerRadius: Radius.l))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.l)
                .strokeBorder(isFocused ? Palette.accent : Palette.textTertiary.opacity(0.4), lineWidth: Stroke.hairline)
        }
        .frame(maxWidth: Dimension.Chat.readableWidth)
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(Palette.surface)
        .disabled(!isEnabled)
    }
}

private struct SessionComposerControls: View {
    let source: SessionChatSource
    let control: (Data) -> Void

    var body: some View {
        HStack(spacing: Spacing.s) {
            if source == .terminal {
                Button("Ctrl-C") { control(Data([3])) }
            }
            Button { control(Data([27])) } label: {
                Label("Interrupt", systemImage: "stop")
            }
            if source == .terminal {
                Button("Return") { control(Data([13])) }
            }
        }
        .font(Typography.caption)
        .buttonStyle(.borderless)
        .foregroundStyle(Palette.textSecondary)
    }
}
