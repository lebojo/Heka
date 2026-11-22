#if os(macOS)
import SwiftUI

struct SheetSpaceReader: NSViewRepresentable {
    @Binding var space: CGSize?

    func makeNSView(context: Context) -> SheetSpaceReaderView {
        SheetSpaceReaderView()
    }

    func updateNSView(_ nsView: SheetSpaceReaderView, context: Context) {
        nsView.onChange = { size in
            DispatchQueue.main.async { if space != size { space = size } }
        }
        nsView.report()
    }
}
#endif
