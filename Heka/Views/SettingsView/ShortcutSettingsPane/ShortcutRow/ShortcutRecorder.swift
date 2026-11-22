#if os(macOS)
import AppKit
import SwiftUI

struct ShortcutRecorder: View {
    @State private var monitor: Any?
    @State private var window: NSWindow?

    @Binding var isRecording: Bool

    let title: LocalizedStringResource
    let symbols: String
    let record: (KeyCombination) -> Void

    var body: some View {
        Button { isRecording.toggle() } label: {
            Text(isRecording ? String(localized: "Type Shortcut…") : symbols)
                .monospaced()
                .frame(minWidth: Dimension.Settings.shortcutWidth)
        }
        .buttonStyle(.bordered)
        .tint(isRecording ? Color.accentColor : nil)
        .accessibilityLabel(Text(title))
        .accessibilityValue(isRecording ? Text("Recording") : Text(symbols))
        .accessibilityHint("Records a new key combination. Press Escape to cancel.")
        .onChange(of: isRecording) { _, isRecording in
            if isRecording { startMonitoring() } else { stopMonitoring() }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification), perform: stopIfWindowResigned)
        .onDisappear(perform: finishRecording)
    }

    private func startMonitoring() {
        guard monitor == nil else { return }
        guard let keyWindow = NSApp.keyWindow else { return finishRecording() }
        window = keyWindow
        AccessibilityNotification.Announcement(String(localized: "Type the new shortcut")).post()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak keyWindow] event in
            guard event.window === keyWindow else { return event }
            handle(event)
            return nil
        }
    }

    private func stopMonitoring() {
        window = nil
        guard let monitor else { return }
        NSEvent.removeMonitor(monitor)
        self.monitor = nil
    }

    private func stopIfWindowResigned(_ notification: Notification) {
        guard isRecording, let window, notification.object as? NSWindow === window else { return }
        finishRecording()
    }

    private func finishRecording() {
        isRecording = false
        stopMonitoring()
    }

    private func handle(_ event: NSEvent) {
        guard event.keyCode != KeyCombination.escapeKeyCode else { return finishRecording() }
        guard let combination = KeyCombination(event: event) else { return NSSound.beep() }
        finishRecording()
        record(combination)
    }
}
#endif
