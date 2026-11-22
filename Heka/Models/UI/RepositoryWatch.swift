import Foundation

struct RepositoryWatch: Equatable, Sendable {
    let worktreePaths: [String]
    let isVisible: Bool
}
