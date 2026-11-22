import Foundation

struct BridgeRequest: Codable, Sendable {
    var id: UUID
    var action: String
    var projectID: UUID?
    var worktreeID: UUID?
    var name: String?
    var branch: String?
    var group: String?
    var worktreeIDs: [UUID]?
    var path: String?
    var directory: String?
    var callerTerminalID: UUID?
    var callerProcessID: Int32?
    var command: [String]
    var force: Bool?
    var deleteBranch: Bool?
    var forceBranch: Bool?
    var terminalID: UUID?
    var text: String?
    var pressesEnter: Bool?
    var keys: [String]?
    var reply: Bool?
    var messages: Int?
    var lines: Int?
    var idleSeconds: Double?
    var waitsForExit: Bool?
    var timeoutSeconds: Double?

    static let longestResponseTimeout = TerminalWait.maximumTimeout + 30

    var responseTimeout: Double {
        action == "terminal.wait" ? (timeoutSeconds ?? TerminalWait.defaultTimeout) + 30 : 120
    }

    var branchRemoval: BranchRemoval {
        get throws {
            guard deleteBranch == true else {
                if forceBranch == true {
                    throw WorkspaceError(message: String(localized: "--force-branch only applies with --delete-branch. Add --delete-branch to delete the branch."))
                }
                return .keep
            }
            return forceBranch == true ? .force : .merged(confirmed: nil)
        }
    }

    func validate() throws {
        if let lines, !(1...TerminalWait.maximumLines).contains(lines) { throw Self.invalidLines }
        if let messages, !(1...TerminalWait.maximumMessages).contains(messages) { throw Self.invalidMessages }
        try Self.validate(seconds: idleSeconds, option: "--idle")
        try Self.validate(seconds: timeoutSeconds, option: "--timeout")
        if let unknown = keys?.first(where: { TerminalKey(name: $0) == nil }) { throw Self.unknownKey(unknown) }
        if let keys, keys.count > TerminalKey.maximumCount {
            throw WorkspaceError(message: String(localized: "Too many keys: \(TerminalKey.maximumCount) at most."))
        }
        if waitsForExit == true, idleSeconds != nil {
            throw WorkspaceError(message: String(localized: "Use either --idle or --exit, not both."))
        }
        if [lines != nil, reply == true, messages != nil].filter({ $0 }).count > 1 {
            throw WorkspaceError(message: String(localized: "Use only one of --lines, --reply and --messages."))
        }
    }

    static var invalidLines: WorkspaceError {
        WorkspaceError(message: String(localized: "--lines must be a whole number from 1 to \(TerminalWait.maximumLines)."))
    }

    static var invalidMessages: WorkspaceError {
        WorkspaceError(message: String(localized: "--messages must be a whole number from 1 to \(TerminalWait.maximumMessages)."))
    }

    static func invalidSeconds(option: String) -> WorkspaceError {
        WorkspaceError(message: String(localized: "\(option) must be a number of seconds greater than 0 and at most \(Int(TerminalWait.maximumTimeout))."))
    }

    static func unknownKey(_ name: String) -> WorkspaceError {
        WorkspaceError(message: String(localized: "Unknown key: \(name). Use \(TerminalKey.names)."))
    }

    private static func validate(seconds: Double?, option: String) throws {
        guard let seconds else { return }
        guard seconds.isFinite, seconds > 0, seconds <= TerminalWait.maximumTimeout else { throw invalidSeconds(option: option) }
    }
}

struct BridgeResponse: Codable, Sendable {
    var ok: Bool
    var message: String?
    var projectID: UUID?
    var worktreeID: UUID?
    var terminalID: UUID?
    var groupID: UUID?
    var path: String?
    var workspace: Workspace?
    var removed: Bool?
    var closesCaller: Bool?
    var branch: String?
    var branchDeleted: Bool?
    var output: String?
    var running: Bool?
    var exitCode: Int32?
    var agent: ConversationAgent?
    var status: String?
    var messages: [SessionMessage]?
}

extension BridgeResponse {
    init(deleting worktree: Worktree, of projectID: UUID, cleanup: BranchCleanup) {
        self.init(ok: true, message: cleanup.failure ?? cleanup.notice, projectID: projectID, worktreeID: worktree.id,
                  path: worktree.path, removed: true, branch: cleanup.branch, branchDeleted: cleanup.reportedDeletion)
    }
}

enum TerminalWait {
    static let defaultIdle: Double = 5
    static let defaultTimeout: Double = 120
    static let maximumTimeout: Double = 3600
    static let defaultLines = 50
    static let maximumLines = 10_000
    static let maximumMessages = 200
}
