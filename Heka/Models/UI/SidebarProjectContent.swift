import Foundation

struct SidebarProjectContent: Equatable {
    struct Group: Identifiable, Equatable {
        let group: WorktreeGroup
        let worktrees: [Worktree]
        let total: Int
        let showsAll: Bool
        var id: UUID { group.id }
    }

    var primary: [Worktree] = []
    var groups: [Group] = []
    var ungrouped: [Worktree] = []
    var showsEverything = false
}

struct SidebarProjectInput: Equatable {
    let project: Project
    let query: String
    let showAll: Bool

    func content() -> SidebarProjectContent {
        let showsEverything = showAll || matches(project.name)
        let groups = project.worktreeGroups.compactMap { group -> SidebarProjectContent.Group? in
            let showsAll = showsEverything || matches(group.name)
            let all = project.worktrees(in: group.id)
            let visible = all.filter { isVisible($0, showsAll: showsAll) }
            guard showsAll || !visible.isEmpty else { return nil }
            return SidebarProjectContent.Group(group: group, worktrees: visible, total: all.count, showsAll: showsAll)
        }
        return SidebarProjectContent(primary: project.worktrees.filter(\.isPrimary), groups: groups,
                                     ungrouped: project.worktrees(in: nil).filter { isVisible($0, showsAll: showsEverything) },
                                     showsEverything: showsEverything)
    }

    private func matches(_ value: String) -> Bool { query.isEmpty || value.localizedStandardContains(query) }

    private func isVisible(_ worktree: Worktree, showsAll: Bool) -> Bool {
        showsAll || matches(worktree.displayName) || worktree.terminals.contains { matches($0.name) }
    }
}
