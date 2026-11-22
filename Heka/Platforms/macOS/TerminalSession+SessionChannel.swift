#if os(macOS)
import Foundation

extension TerminalSession: SessionChannel {
    func sendMessage(_ text: String) async throws {
        try await send(Data((text + "\r").utf8), message: text, from: .local)
    }

    func sendControl(_ data: Data) async throws {
        try await send(data, from: .local)
    }

    func runCommand(_ command: AgentCommand) async throws {
        try await run(command, from: .local)
    }
}
#endif
