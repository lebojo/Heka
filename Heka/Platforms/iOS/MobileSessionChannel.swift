import Foundation

struct MobileSessionChannel: SessionChannel {
    let store: MobileWorkspaceStore
    let terminalID: UUID

    func sendMessage(_ text: String) async throws {
        try await store.input(Data((text + "\r").utf8), terminal: terminalID, message: text)
    }

    func sendControl(_ data: Data) async throws {
        try await store.input(data, terminal: terminalID)
    }

    func runCommand(_ command: AgentCommand) async throws {
        try await store.input(command.input, terminal: terminalID, message: command.text)
    }
}
