import SwiftUI

struct SessionChatView: View {
    @State private var draft = ""
    @State private var images: [URL] = []
    @State private var sending = false
    @State private var awaitsAgent = false
    @State private var error: String?

    let messages: [SessionMessage]
    let source: SessionChatSource
    let options: AgentOptions
    let commands: [SlashCommand]
    let isEnabled: Bool
    let status: AgentStatus?
    let send: (String) async throws -> Void
    let control: (Data) async throws -> Void
    let run: (AgentCommand) async throws -> Void

    private var isAgentWorking: Bool {
        source.agent != nil && ChatActivity(status: status, isSending: sending || awaitsAgent, isEnabled: isEnabled).showsIndicator
    }

    var body: some View {
        SessionTranscriptList(messages: messages, source: source, showsTypingIndicator: isAgentWorking)
        .background(Palette.surface)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SessionComposer(draft: $draft, images: $images, source: source, options: options, commands: commands, sending: sending, isEnabled: isEnabled,
                            isBusy: !(status?.acceptsCommands ?? true), isWorking: isAgentWorking, submit: submit, control: sendControl, run: runCommand)
        }
        .onChange(of: status) { awaitsAgent = false }
        .task(id: awaitsAgent) {
            guard awaitsAgent else { return }
            try? await Task.sleep(for: ChatActivity.agentStartGrace)
            awaitsAgent = false
        }
        .alert("Couldn’t Send", isPresented: $error.isPresent) {
            Button("OK") { error = nil }
        } message: { Text(error ?? "") }
    }

    private func submit() {
        guard isEnabled, !sending, !(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && images.isEmpty) else { return }
        let text = draft
        let attached = images
        let message = source.agent?.prompt(text, attaching: attached) ?? text
        sending = true
        Task {
            defer { sending = false }
            do {
                try await send(message)
                awaitsAgent = true
                if draft == text { draft = "" }
                if images == attached { images = [] }
            } catch { self.error = error.localizedDescription }
        }
    }

    private func runCommand(_ command: AgentCommand) async -> Bool {
        do {
            try await run(command)
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    private func sendControl(_ data: Data) {
        Task {
            do { try await control(data) }
            catch { self.error = error.localizedDescription }
        }
    }
}

