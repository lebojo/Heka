import SwiftUI

struct TerminalLayoutView<Pane: View>: View {
    let layout: TerminalLayout
    let panes: [UUID: Pane]

    var body: some View {
        switch layout {
        case .terminal(let id):
            panes[id]
                .id(id)
                .frame(minWidth: Dimension.Detail.paneMinLength, minHeight: Dimension.Detail.paneMinLength)
        case .split(.horizontal, let children, _):
            HSplitView {
                ForEach(children) { child in
                    TerminalLayoutView(layout: child, panes: panes)
                }
            }
        case .split(.vertical, let children, _):
            VSplitView {
                ForEach(children) { child in
                    TerminalLayoutView(layout: child, panes: panes)
                }
            }
        }
    }
}
