import Foundation

struct WorktreeFolderWatch: Equatable, Sendable {
    let creationDirectory: URL
    let directories: [URL]
    let isVisible: Bool
}
