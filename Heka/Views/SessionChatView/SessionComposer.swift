import SwiftUI

struct SessionComposer: View {
    @AppStorage("recentSlashCommands") private var recentCommands = ""
    @AppStorage(BorderBeamAppearance.storageKey) private var beam = BorderBeamAppearance()

    @Environment(ChatDrafts.self) private var drafts
    @Environment(SessionChat.self) private var chat

    @State private var commandMatches: [SlashCommandMatch] = []
    @State private var commandSelection = 0
    @State private var isCommandNavigated = false

    @FocusState private var isFocused: Bool

    let source: SessionChatSource
    let options: AgentOptions
    let commands: [SlashCommand]
    let isEnabled: Bool
    let isBusy: Bool
    let isWorking: Bool
    let isInterruptible: Bool

    private var draft: ChatDraft { drafts[terminal: chat.terminal] }

    private var prompt: String {
        source.agent.map { String(localized: "Message \($0.title)") } ?? String(localized: "Message or command")
    }

    private var recentCommandNames: [String] {
        recentCommands.split(separator: "\n").map(String.init)
    }

    private var pendingArgument: String? {
        commands.first { SlashCommandMatcher.insertion(for: $0) == draft.text }?.argument
    }

    private var acceptsImages: Bool { isEnabled && source.agent != nil }

    private var canSend: Bool { !chat.isSending && !draft.isBlank }

    private var sendShortcut: KeyboardShortcut? {
        isFocused ? ShortcutStore.shared.combination(for: .sendMessage).keyboardShortcut : nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            if !draft.images.isEmpty {
                SessionComposerImages(images: draft.images)
            }
            if !draft.visiblePastes.isEmpty {
                SessionComposerPastes(pastes: draft.visiblePastes)
            }
            TextField(prompt, text: Bindable(drafts)[terminal: chat.terminal].editedText, axis: .vertical)
                .font(Font.chatInput)
                .autocorrectionDisabled()
                .commandInputTraits()
                .submitsChatMessage(perform: submit)
                .lineLimit(3...8).textFieldStyle(.plain)
                .focused($isFocused)
                .onKeyPress(keys: [.upArrow, .downArrow, .tab, .return, .escape], action: handleCommandKey)
                .onChange(of: draft.text, initial: true, refreshCommandMatches)
                .onChange(of: commands, refreshCommandMatches)
                .accessibilityLabel(prompt)
                .padding(.horizontal, Spacing.xs)

            HStack(spacing: Spacing.m) {
                if source.supportsAgentOptions {
                    SessionAgentOptions(source: source, reported: options, isBusy: isBusy)
                }
                SessionComposerControls(source: source, isBusy: isBusy, isInterruptible: isInterruptible)
                Spacer(minLength: Spacing.s)
                if let pendingArgument {
                    Text("Add \(pendingArgument)")
                        .font(Font.captionMono).foregroundStyle(Color.textTertiary)
                        .lineLimit(1)
                }
                #if os(macOS)
                Text("⇧Return for a new line")
                    .font(Font.xs).foregroundStyle(Color.textTertiary)
                    .lineLimit(1)
                    .layoutPriority(-1)
                #endif
                SessionSendButton(isSending: chat.isSending, action: submit)
                    .keyboardShortcut(sendShortcut)
                    .disabled(!canSend)
            }
        }
        .pastesImages(isEnabled: acceptsImages, isFocused: isFocused, add: attach)
        .padding(Spacing.l)
        .background(Color.control, in: RoundedRectangle(cornerRadius: Radius.l))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.l)
                .strokeBorder(isFocused ? beam.beamColor(for: source.agent) : Color.textTertiary.opacity(0.4), lineWidth: Stroke.hairline)
        }
        .borderBeam(shape: .rounded(Radius.l), isActive: isWorking && beam.isEnabled, colors: beam.beamColors(for: source.agent))
        .overlay(alignment: .top) {
            if !commandMatches.isEmpty {
                SessionCommandPopup(matches: commandMatches, selection: commandSelection, accept: accept)
                    .alignmentGuide(.top) { $0[.bottom] + Spacing.s }
            }
        }
        .frame(maxWidth: Dimension.Chat.readableWidth)
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(.background)
        .disabled(!isEnabled)
    }

    private func submit() {
        guard isEnabled, !chat.isSending, !draft.isBlank else { return }
        let terminal = chat.terminal
        let sent = drafts.take(from: terminal)
        let message = source.agent?.prompt(sent.message, attaching: sent.images) ?? sent.message
        let pending = PendingChatMessage(text: sent.message, prompt: message, agent: source.agent)
        Task {
            if await !chat.send(message, showing: pending) { drafts.restore(sent, to: terminal) }
        }
    }

    private func attach(_ images: [URL]) {
        drafts[terminal: chat.terminal].images.append(contentsOf: images)
    }

    private func refreshCommandMatches() {
        commandSelection = 0
        isCommandNavigated = false
        guard let query = SlashCommandMatcher.query(in: draft.text) else { return commandMatches = [] }
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
        guard let command = SlashCommandMatcher.commandToAcceptOnReturn(draft: draft.text, matches: commandMatches,
                                                                          selection: commandSelection,
                                                                          isNavigated: isCommandNavigated) else { return .ignored }
        accept(command)
        return .handled
    }

    private func accept(_ command: SlashCommand) {
        drafts[terminal: chat.terminal].text = SlashCommandMatcher.insertion(for: command)
        recentCommands = SlashCommandMatcher.remembering(command, in: recentCommandNames).joined(separator: "\n")
        isFocused = true
    }
}
