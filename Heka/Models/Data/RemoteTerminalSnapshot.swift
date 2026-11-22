import Foundation

struct RemoteTerminalSnapshot: Codable, Sendable {
    static let maximumColumns = 2_000
    static let maximumRows = 1_000

    let identity: UUID
    let isChat: Bool
    let output: Data
    let columns: Int
    let rows: Int
    let transcript: [SessionMessage]
    let transcriptDropped: Int
    let transcriptStart: Int
    let transcriptAppend: SessionTextAppend?
    let hasExited: Bool
    let exitCode: Int32?
    var chatSource: SessionChatSource = .terminal
    var agentOptions: AgentOptions?

    var mirroredColumns: Int { min(max(columns, 1), Self.maximumColumns) }
    var mirroredRows: Int { min(max(rows, 1), Self.maximumRows) }
}
