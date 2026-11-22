import Foundation

struct RemovalConfirmations: Codable, Hashable, Sendable {
    var onProjectRemoval = true
    var onTerminalClosing = true

    func requires(_ removal: Removal) -> Bool {
        switch removal {
        case .project: onProjectRemoval
        case .terminal: onTerminalClosing
        case .worktree, .orphanWorktree: true
        }
    }

    mutating func skip(_ removal: Removal) {
        switch removal {
        case .project: onProjectRemoval = false
        case .terminal: onTerminalClosing = false
        case .worktree, .orphanWorktree: break
        }
    }
}

extension RemovalConfirmations {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let onProjectRemoval = try? container.decodeIfPresent(Bool.self, forKey: .onProjectRemoval) { self.onProjectRemoval = onProjectRemoval }
        if let onTerminalClosing = try? container.decodeIfPresent(Bool.self, forKey: .onTerminalClosing) { self.onTerminalClosing = onTerminalClosing }
    }
}
