import Foundation

enum WorkspaceSheet: Identifiable, Equatable {
    case folder(parentID: UUID?)
    case rename(UUID, String)
    case worktree(UUID, String)
    case worktreeGroup(projectID: UUID, worktreeID: UUID?)

    var id: String {
        switch self {
        case .folder(let parentID): "folder-\(parentID?.uuidString ?? "root")"
        case .rename(let id, _): "rename-\(id)"
        case .worktree(let id, _): "worktree-\(id)"
        case .worktreeGroup(let projectID, let worktreeID): "worktree-group-\(projectID)-\(worktreeID?.uuidString ?? "empty")"
        }
    }
}
