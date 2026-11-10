import Foundation

extension WorkspaceStore: SidebarModel {
    var sidebarActivity: SidebarActivity {
        let worktrees = projects.flatMap(\.worktrees)
        let terminals = worktrees.flatMap(\.terminals).reduce(into: [UUID: TerminalSummary]()) { summaries, terminal in
            summaries[terminal.id] = terminalSummary(terminal.id)
        }
        let branches = worktrees.reduce(into: [String: GitBranch]()) { branches, worktree in
            branches[worktree.path] = branch(at: worktree.path)
        }
        return SidebarActivity(terminals: terminals, branches: branches)
    }

    func terminalSummary(_ id: UUID) -> TerminalSummary? {
        sessions.session(id).map { session in
            TerminalSummary(agent: session.agentKind, status: session.agentStatus, hasExited: session.hasExited,
                            divergentBranch: session.divergentBranch, subagents: session.subagents)
        }
    }

    func branch(at path: String) -> GitBranch? {
        sessions.branch(at: path)
    }
}
