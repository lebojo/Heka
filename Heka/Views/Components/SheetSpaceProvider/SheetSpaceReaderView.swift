#if os(macOS)
import AppKit

final class SheetSpaceReaderView: NSView {
    var onChange: (CGSize?) -> Void = { _ in }
    private var observations: [NSObjectProtocol] = []

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        observations.forEach(NotificationCenter.default.removeObserver)
        observations = []
        guard let window else { return onChange(nil) }
        let notifications: [(Notification.Name, AnyObject?)] = [(NSWindow.didChangeScreenNotification, window),
                                                               (NSWindow.didEndLiveResizeNotification, window),
                                                               (NSApplication.didChangeScreenParametersNotification, nil)]
        observations = notifications.map { name, object in
            NotificationCenter.default.addObserver(forName: name, object: object, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.report() }
            }
        }
        report()
    }

    func report() {
        guard let window, let screen = window.screen ?? NSScreen.main else { return onChange(nil) }
        let titleBarHeight = window.frame.height - window.contentLayoutRect.height
        onChange(CGSize(width: screen.visibleFrame.width, height: screen.visibleFrame.height - titleBarHeight))
    }
}
#endif
