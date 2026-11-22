#if os(macOS)
import AppKit
import Carbon.HIToolbox

final class ComposerPasteView: NSView {
    var isEnabled = false {
        didSet { updateMonitor() }
    }
    var add: @MainActor ([URL]) -> Void = { _ in }

    private var monitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        updateMonitor()
    }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    private func updateMonitor() {
        let isMonitoring = isEnabled && window != nil
        guard isMonitoring != (monitor != nil) else { return }
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        } else {
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                self?.handle(event) ?? event
            }
        }
    }

    private func handle(_ event: NSEvent) -> NSEvent? {
        guard event.window === window, Self.isPaste(event), let content = ComposerPasteboard.content(of: .general) else { return event }
        let add = add
        Task { add(await ComposerPasteboard.store(content)) }
        return nil
    }

    private static func isPaste(_ event: NSEvent) -> Bool {
        guard event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command else { return false }
        let key = event.charactersIgnoringModifiers ?? ""
        return key == "v" || event.keyCode == UInt16(kVK_ANSI_V) && !key.allSatisfy(\.isASCII)
    }
}
#endif
