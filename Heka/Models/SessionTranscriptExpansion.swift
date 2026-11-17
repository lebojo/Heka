import Observation

@MainActor
@Observable
final class SessionTranscriptExpansion {
    private var expandedTools: Set<String> = []
    private var expandedGroups: Set<String> = []

    func isToolExpanded(_ id: String) -> Bool { expandedTools.contains(id) }

    func setTool(_ id: String, expanded: Bool) {
        if expanded {
            expandedTools.insert(id)
            expandedGroups.insert(id)
        } else {
            expandedTools.remove(id)
            expandedGroups.remove(id)
        }
    }

    func isGroupExpanded(_ memberIDs: [String]) -> Bool { memberIDs.contains(where: expandedGroups.contains) }

    func setGroup(_ memberIDs: [String], expanded: Bool) {
        if expanded { expandedGroups.formUnion(memberIDs) } else { expandedGroups.subtract(memberIDs) }
    }
}
