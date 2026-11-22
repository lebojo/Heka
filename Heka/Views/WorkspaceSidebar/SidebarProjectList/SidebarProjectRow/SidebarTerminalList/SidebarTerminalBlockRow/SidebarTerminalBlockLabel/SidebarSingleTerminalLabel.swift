import SwiftUI

struct SidebarSingleTerminalLabel: View {
    @Environment(SidebarStore.self) private var store

    let terminal: TerminalRecord

    var body: some View {
        SidebarTerminalLabel(name: terminal.name, summary: store.terminalSummary(terminal.id))
            .padding(.vertical, Spacing.xxs)
            #if os(macOS)
            .terminalDragSource(terminal.id)
            #endif
    }
}
