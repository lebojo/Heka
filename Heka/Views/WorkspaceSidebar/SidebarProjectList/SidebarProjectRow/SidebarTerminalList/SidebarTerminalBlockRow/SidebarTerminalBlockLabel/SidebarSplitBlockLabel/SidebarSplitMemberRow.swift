import SwiftUI

struct SidebarSplitMemberRow: View {
    @Environment(SidebarStore.self) private var store

    let terminal: TerminalRecord
    let isFocused: Bool

    var body: some View {
        Button { store.selection = terminal.id } label: {
            SidebarTerminalLabel(name: terminal.name, summary: store.terminalSummary(terminal.id))
                .fontWeight(isFocused ? .semibold : nil)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isFocused ? .isSelected : [])
        #if os(macOS)
        .terminalDragSource(terminal.id)
        #endif
        .contextMenu { SidebarTerminalMenu(terminal: terminal) }
    }
}
