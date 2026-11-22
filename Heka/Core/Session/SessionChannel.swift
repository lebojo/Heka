import Foundation

@MainActor protocol SessionChannel {
    var terminalID: UUID { get }

    func sendMessage(_ text: String) async throws
    func sendControl(_ data: Data) async throws
    func runCommand(_ command: AgentCommand) async throws
}
