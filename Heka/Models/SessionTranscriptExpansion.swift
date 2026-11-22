import Observation

@MainActor
@Observable
final class SessionTranscriptExpansion {
    private var expandedTools: Set<String> = []
    private var expandedGroups: Set<String> = []

    subscript(toolExpanded id: String) -> Bool {
        get { expandedTools.contains(id) }
        set {
            if newValue {
                expandedTools.insert(id)
                expandedGroups.insert(id)
            } else {
                expandedTools.remove(id)
                expandedGroups.remove(id)
            }
        }
    }

    subscript(groupExpanded memberIDs: [String]) -> Bool {
        get { memberIDs.contains(where: expandedGroups.contains) }
        set {
            if newValue { expandedGroups.formUnion(memberIDs) } else { expandedGroups.subtract(memberIDs) }
        }
    }
}
