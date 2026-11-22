#if os(macOS)
import AppKit

final class SheetResizeObserverView: NSView {
    private let kind: PreviewSheetKind
    private var observation: NSObjectProtocol?

    init(kind: PreviewSheetKind) {
        self.kind = kind
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        observation.map(NotificationCenter.default.removeObserver)
        observation = nil
        guard let window else { return }
        observation = NotificationCenter.default.addObserver(forName: NSWindow.didEndLiveResizeNotification,
                                                             object: window, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.save() }
        }
    }

    private func save() {
        guard let size = window?.contentLayoutRect.size,
              PreviewSheetKind.isValid(size.width), PreviewSheetKind.isValid(size.height) else { return }
        UserDefaults.standard.set(Double(size.width), forKey: kind.widthKey)
        UserDefaults.standard.set(Double(size.height), forKey: kind.heightKey)
    }
}
#endif
