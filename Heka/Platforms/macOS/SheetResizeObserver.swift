import AppKit
import SwiftUI

struct SheetResizeObserver: NSViewRepresentable {
    final class ObserverView: NSView {
        private let kind: PreviewSheetKind
        private let initialSize: CGSize
        private var observation: NSObjectProtocol?

        init(kind: PreviewSheetKind, initialSize: CGSize) {
            self.kind = kind
            self.initialSize = initialSize
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) { nil }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            observation.map(NotificationCenter.default.removeObserver)
            observation = nil
            guard let window else { return }
            if #unavailable(macOS 15) { makeResizable(window) }
            observation = NotificationCenter.default.addObserver(forName: NSWindow.didEndLiveResizeNotification,
                                                                 object: window, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.save() }
            }
        }

        private func makeResizable(_ window: NSWindow) {
            window.styleMask.insert(.resizable)
            window.contentMinSize = PreviewSheetKind.minimumSize
            window.setContentSize(initialSize)
        }

        private func save() {
            guard let size = window?.contentLayoutRect.size,
                  PreviewSheetKind.isValid(size.width), PreviewSheetKind.isValid(size.height) else { return }
            UserDefaults.standard.set(Double(size.width), forKey: kind.widthKey)
            UserDefaults.standard.set(Double(size.height), forKey: kind.heightKey)
        }
    }

    let kind: PreviewSheetKind
    let initialSize: CGSize

    func makeNSView(context: Context) -> ObserverView {
        ObserverView(kind: kind, initialSize: initialSize)
    }

    func updateNSView(_ nsView: ObserverView, context: Context) {}
}
