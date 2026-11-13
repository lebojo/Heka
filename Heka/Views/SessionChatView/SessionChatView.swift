import SwiftUI

struct SessionChatView: View {
    @State private var draft = ""
    @State private var sending = false
    @State private var error: String?

    let messages: [SessionMessage]
    let source: SessionChatSource
    let options: AgentOptions
    let commands: [SlashCommand]
    let isEnabled: Bool
    let isBusy: Bool
    let send: (String) async throws -> Void
    let control: (Data) async throws -> Void
    let run: (AgentCommand) async throws -> Void

    var body: some View {
        SessionTranscriptList(messages: messages, source: source)
        .background(Palette.surface)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SessionComposer(draft: $draft, source: source, options: options, commands: commands, sending: sending, isEnabled: isEnabled,
                            isBusy: isBusy, submit: submit, control: sendControl, run: runCommand)
        }
        .alert("Couldn’t Send", isPresented: $error.isPresent) {
            Button("OK") { error = nil }
        } message: { Text(error ?? "") }
    }

    private func submit() {
        guard isEnabled, !sending, !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let text = draft
        sending = true
        Task {
            defer { sending = false }
            do {
                try await send(text)
                if draft == text { draft = "" }
            } catch { self.error = error.localizedDescription }
        }
    }

    private func runCommand(_ command: AgentCommand) {
        Task {
            do { try await run(command) }
            catch { self.error = error.localizedDescription }
        }
    }

    private func sendControl(_ data: Data) {
        Task {
            do { try await control(data) }
            catch { self.error = error.localizedDescription }
        }
    }
}

