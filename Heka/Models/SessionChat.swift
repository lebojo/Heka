import Foundation
import Observation

@MainActor @Observable final class SessionChat {
    private(set) var isSending = false
    var awaitsAgent = false
    var error: String?
    private(set) var requestedOptions: AgentOptions?
    private(set) var pendingMessages: [PendingChatMessage] = []

    @ObservationIgnored private let channel: any SessionChannel
    @ObservationIgnored private var pending = PendingChatMessages()

    init(channel: any SessionChannel) {
        self.channel = channel
    }

    var terminal: UUID { channel.terminalID }

    var sendingPendingIDs: [UUID] {
        pendingMessages.filter { $0.state == .sending }.map(\.id)
    }

    subscript(model reported: AgentOptions) -> AgentModel {
        get { shownOptions(reported).model }
        set { request(shownOptions(reported).switching(to: newValue, efforts: newValue.efforts), with: newValue.command) }
    }

    subscript(effort reported: AgentOptions) -> AgentEffort {
        get { shownOptions(reported).effort }
        set {
            var options = shownOptions(reported)
            options.effort = newValue
            request(options, with: newValue.command)
        }
    }

    func shownOptions(_ reported: AgentOptions) -> AgentOptions {
        requestedOptions ?? reported
    }

    func forgetRequestedOptions() {
        requestedOptions = nil
    }

    func send(_ message: String, showing pendingMessage: PendingChatMessage? = nil) async -> Bool {
        guard !isSending else { return false }
        isSending = true
        defer { isSending = false }
        if let pendingMessage { updatePending { $0.add(pendingMessage) } }
        do {
            try await channel.sendMessage(message)
            awaitsAgent = true
            return true
        } catch {
            if let pendingMessage { updatePending { $0.remove(pendingMessage.id) } }
            self.error = error.localizedDescription
            return false
        }
    }

    func reconcilePending(with messages: [SessionMessage]) {
        updatePending { $0.reconcile(with: messages) }
    }

    func markPendingUnconfirmed(_ ids: [UUID]) {
        updatePending { $0.markUnconfirmed(ids) }
    }

    func control(_ data: Data) {
        Task {
            do { try await channel.sendControl(data) }
            catch { self.error = error.localizedDescription }
        }
    }

    func run(_ command: AgentCommand) async -> Bool {
        do {
            try await channel.runCommand(command)
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    private func updatePending(_ change: (inout PendingChatMessages) -> Void) {
        change(&pending)
        if pendingMessages != pending.items { pendingMessages = pending.items }
    }

    private func request(_ options: AgentOptions, with command: AgentCommand) {
        requestedOptions = options
        Task {
            if await !run(command), requestedOptions == options { requestedOptions = nil }
        }
    }
}
