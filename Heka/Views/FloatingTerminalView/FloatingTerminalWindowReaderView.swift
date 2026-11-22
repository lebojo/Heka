import AppKit

final class FloatingTerminalWindowReaderView: NSView {
    private let store: FloatingTerminalStore

    init(store: FloatingTerminalStore) {
        self.store = store
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        store.attach(window)
    }
}
