import Foundation
import Observation

@MainActor @Observable final class SessionChat {
    private(set) var isSending = false
    var awaitsAgent = false
    var error: String?
    private(set) var requestedOptions: AgentOptions?

    @ObservationIgnored private let channel: any SessionChannel

    init(channel: any SessionChannel) {
        self.channel = channel
    }

    var terminal: UUID { channel.terminalID }

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

    func send(_ message: String) async -> Bool {
        guard !isSending else { return false }
        isSending = true
        defer { isSending = false }
        do {
            try await channel.sendMessage(message)
            awaitsAgent = true
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
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

    private func request(_ options: AgentOptions, with command: AgentCommand) {
        requestedOptions = options
        Task {
            if await !run(command), requestedOptions == options { requestedOptions = nil }
        }
    }
}
