import SwiftUI

struct TerminalDropHighlight: View {
    let edge: DropEdge
    let size: CGSize

    var body: some View {
        DropTargetHighlight()
            .frame(width: edge.axis == .horizontal ? size.width / 2 : size.width,
                   height: edge.axis == .vertical ? size.height / 2 : size.height)
    }
}
