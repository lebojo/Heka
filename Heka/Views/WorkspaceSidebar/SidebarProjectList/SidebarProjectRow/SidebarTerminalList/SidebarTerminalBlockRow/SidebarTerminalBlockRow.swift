import SwiftUI

struct SidebarTerminalBlockRow: View {
    @Environment(SidebarStore.self) private var store

    let block: SidebarTerminalBlock

    private var subagents: [Subagent] {
        block.terminalIDs.flatMap { store.terminalSummary($0)?.subagents ?? [] }
            .filter { $0.isVisible || $0.id == store.selection }
    }

    var body: some View {
        let subagents = subagents
        if subagents.isEmpty {
            SidebarTerminalBlockLabel(block: block)
        } else {
            DisclosureGroup(isExpanded: Bindable(store)[expanded: block.id]) {
                ForEach(subagents) { subagent in
                    SidebarSubagentRow(subagent: subagent)
                }
            } label: {
                SidebarTerminalBlockLabel(block: block)
            }
        }
    }
}
