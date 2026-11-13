import AppKit
import SwiftUI

final class TerminalHostView: NSView {
    let terminal: ActivityTerminalView
    private let margin = CALayer()
    private var backgroundObservation: NSKeyValueObservation?

    override var isFlipped: Bool { true }

    init(terminal: ActivityTerminalView) {
        self.terminal = terminal
        super.init(frame: .zero)
        clipsToBounds = true
        wantsLayer = true
        margin.zPosition = -1
        layer?.addSublayer(margin)
        terminal.removeFromSuperview()
        terminal.translatesAutoresizingMaskIntoConstraints = true
        terminal.autoresizingMask = []
        terminal.wantsLayer = true
        terminal.postsFrameChangedNotifications = true
        addSubview(terminal)
        NotificationCenter.default.addObserver(self, selector: #selector(terminalFrameDidChange),
                                               name: NSView.frameDidChangeNotification, object: terminal)
        backgroundObservation = terminal.layer?.observe(\.backgroundColor) { [weak self] _, _ in
            DispatchQueue.main.async { self?.needsDisplay = true }
        }
    }

    required init?(coder: NSCoder) { nil }

    override var wantsUpdateLayer: Bool { true }

    override func updateLayer() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        margin.backgroundColor = terminal.layer?.backgroundColor
        margin.frame = marginFrame
        CATransaction.commit()
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        layoutTerminal()
    }

    private var marginFrame: NSRect {
        let insets = Dimension.Detail.terminalInsets
        let frame = terminal.frame
        return NSRect(x: frame.minX - insets.leading, y: frame.minY - insets.top,
                      width: frame.width + insets.leading + insets.trailing,
                      height: frame.height + insets.top + insets.bottom)
    }

    @objc private func terminalFrameDidChange() {
        needsDisplay = true
    }

    private func layoutTerminal() {
        let insets = Dimension.Detail.terminalInsets
        let available = NSRect(x: insets.leading, y: insets.top,
                               width: max(0, bounds.width - insets.leading - insets.trailing),
                               height: max(0, bounds.height - insets.top - insets.bottom))
        let frame = backingAlignedRect(available, options: .alignAllEdgesNearest)
        terminal.setFrameOrigin(frame.origin)
        terminal.setFrameSize(frame.size)
        needsDisplay = true
    }
}
