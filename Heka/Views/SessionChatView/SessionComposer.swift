import SwiftUI

struct SessionComposer: View {
    @AppStorage("recentSlashCommands") private var recentCommands = ""

    @State private var commandMatches: [SlashCommandMatch] = []
    @State private var commandSelection = 0
    @State private var isCommandNavigated = false

    @FocusState private var isFocused: Bool

    @Binding var draft: String

    let source: SessionChatSource
    let options: AgentOptions
    let commands: [SlashCommand]
    let sending: Bool
    let isEnabled: Bool
    let isBusy: Bool
    let submit: () -> Void
    let control: (Data) -> Void
    let run: (AgentCommand) async -> Bool

    private var prompt: String {
        source.agent.map { String(localized: "Message \($0.title)") } ?? String(localized: "Message or command")
    }

    private var recentCommandNames: [String] {
        recentCommands.split(separator: "\n").map(String.init)
    }

    private var pendingArgument: String? {
        commands.first { SlashCommandMatcher.insertion(for: $0) == draft }?.argument
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
                .onKeyPress(keys: [.upArrow, .downArrow, .tab, .return, .escape], action: handleCommandKey)
                .onChange(of: draft, initial: true, refreshCommandMatches)
                .onChange(of: commands, refreshCommandMatches)
                .accessibilityLabel(prompt)
                .padding(.horizontal, Spacing.xs)

            if source.supportsAgentOptions {
                SessionAgentOptions(source: source, reported: options, isBusy: isBusy, run: run)
            }

            HStack(spacing: Spacing.m) {
                SessionComposerControls(source: source, control: control)
                Spacer(minLength: Spacing.s)
                if let pendingArgument {
                    Text("Add \(pendingArgument)")
                        .font(Typography.captionMono).foregroundStyle(Palette.textTertiary)
                }
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
        .overlay(alignment: .top) {
            if !commandMatches.isEmpty {
                SessionCommandPopup(matches: commandMatches, selection: commandSelection, accept: accept)
                    .alignmentGuide(.top) { $0[.bottom] + Spacing.s }
            }
        }
        .frame(maxWidth: Dimension.Chat.readableWidth)
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(Palette.surface)
        .disabled(!isEnabled)
    }

    private func refreshCommandMatches() {
        commandSelection = 0
        isCommandNavigated = false
        guard let query = SlashCommandMatcher.query(in: draft) else { return commandMatches = [] }
        commandMatches = SlashCommandMatcher.matches(for: query, in: commands, recent: recentCommandNames)
    }

    private func handleCommandKey(_ press: KeyPress) -> KeyPress.Result {
        guard !commandMatches.isEmpty, press.modifiers.isDisjoint(with: [.shift, .control, .option, .command]) else { return .ignored }
        switch press.key {
        case .upArrow: moveCommandSelection(by: -1)
        case .downArrow: moveCommandSelection(by: 1)
        case .escape: commandMatches = []
        case .tab: accept(commandMatches[commandSelection].command)
        default: return acceptOnReturn()
        }
        return .handled
    }

    private func moveCommandSelection(by offset: Int) {
        commandSelection = (commandSelection + offset + commandMatches.count) % commandMatches.count
        isCommandNavigated = true
    }

    private func acceptOnReturn() -> KeyPress.Result {
        guard let command = SlashCommandMatcher.commandToAcceptOnReturn(draft: draft, matches: commandMatches,
                                                                          selection: commandSelection,
                                                                          isNavigated: isCommandNavigated) else { return .ignored }
        accept(command)
        return .handled
    }

    private func accept(_ command: SlashCommand) {
        draft = SlashCommandMatcher.insertion(for: command)
        recentCommands = SlashCommandMatcher.remembering(command, in: recentCommandNames).joined(separator: "\n")
        isFocused = true
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
