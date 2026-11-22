import AppKit
import SwiftUI

struct NativeTerminalView: NSViewRepresentable {
    let session: TerminalSession
    let appearance: TerminalAppearance
    let isFocused: Bool
    let focus: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView {
        let terminal = session.view
        let host = TerminalHostView(terminal: terminal)
        host.setAccessibilityLabel(String(localized: "Interactive Terminal"))
        applyAppearance()
        let coordinator = context.coordinator
        coordinator.focus = focus
        coordinator.wasFocused = isFocused
        coordinator.eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown, .keyUp]) { [weak host] event in
            guard let host, event.window === host.window else { return event }
            if event.type == .keyDown || event.type == .keyUp {
                guard host.window?.firstResponder === host.terminal else { return event }
                return host.terminal.routeKey(event)
            } else if host.bounds.contains(host.convert(event.locationInWindow, from: nil)) {
                coordinator.focus()
            }
            return event
        }
        if isFocused { takeFocus() }
        return host
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        applyAppearance()
        context.coordinator.focus = focus
        if isFocused, !context.coordinator.wasFocused { takeFocus() }
        context.coordinator.wasFocused = isFocused
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        if let monitor = coordinator.eventMonitor { NSEvent.removeMonitor(monitor) }
        coordinator.eventMonitor = nil
    }

    private func applyAppearance() {
        if session.view.apply(appearance) { session.view.refitRemoteGrid() }
    }

    private func takeFocus() {
        let terminal = session.view
        let keyboardNavigation = Self.isKeyboardNavigation(in: NSApp.keyWindow)
        DispatchQueue.main.async {
            guard !keyboardNavigation, let window = terminal.window else { return }
            window.makeFirstResponder(terminal)
        }
    }

    private static func isKeyboardNavigation(in window: NSWindow?) -> Bool {
        guard let event = NSApp.currentEvent, event.type == .keyDown, !event.modifierFlags.contains(.command) else { return false }
        let responder = window?.firstResponder
        return responder is NSTableView || responder is NSText
    }

    final class Coordinator {
        var wasFocused = false
        var focus: () -> Void = {}
        var eventMonitor: Any?
    }
}
