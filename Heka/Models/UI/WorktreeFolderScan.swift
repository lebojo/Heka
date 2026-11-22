import Foundation

struct WorktreeFolderScan: Equatable, Sendable {
    let directories: [URL]
    let knownPaths: [String]
    let isVisible: Bool
}
