import SwiftUI

struct SheetResizeObserver: NSViewRepresentable {
    let kind: PreviewSheetKind

    func makeNSView(context: Context) -> SheetResizeObserverView {
        SheetResizeObserverView(kind: kind)
    }

    func updateNSView(_ nsView: SheetResizeObserverView, context: Context) {}
}
