import SwiftUI

struct FloatingTerminalView: View {
    @Environment(FloatingTerminalStore.self) private var floating

    var body: some View {
        VStack(spacing: 0) {
            FloatingTerminalTabBar()
            Divider()
            if let tab = floating.state.selectedTab, let focusedID = floating.state.focusedID {
                TerminalLayoutView(layout: tab.layout, panes: tab.layout.terminalIDs.reduce(into: [:]) { panes, id in
                    panes[id] = FloatingTerminalPane(id: id, isFocused: id == focusedID, isSplit: tab.layout.isSplit)
                })
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                Divider()
                TerminalFooter(session: floating.session(focusedID), path: floating.directory(of: focusedID))
            } else {
                Spacer()
            }
        }
        .background(Color.surface)
        .background { FloatingTerminalWindowReader() }
        .previewSheetFrame(.floatingTerminal)
        .onAppear { floating.prepare() }
    }
}
