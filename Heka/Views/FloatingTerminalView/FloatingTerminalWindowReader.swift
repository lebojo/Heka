import SwiftUI

struct FloatingTerminalWindowReader: NSViewRepresentable {
    @Environment(FloatingTerminalStore.self) private var floating

    func makeNSView(context: Context) -> FloatingTerminalWindowReaderView {
        FloatingTerminalWindowReaderView(store: floating)
    }

    func updateNSView(_ nsView: FloatingTerminalWindowReaderView, context: Context) {}
}
