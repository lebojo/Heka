import Foundation

struct RemovalPrompt: Hashable, Sendable {
    let removal: Removal
    let deletableBranch: String?
}
