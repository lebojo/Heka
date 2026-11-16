#if os(macOS)
import AppKit
import SwiftUI

struct ShortcutRecorder: View {
    @State private var monitor: Any?

    @Binding var isRecording: Bool

    let title: LocalizedStringResource
    let symbols: String
    let record: (KeyCombination) -> Void

    var body: some View {
        Button(action: toggleRecording) {
            Text(isRecording ? String(localized: "Type Shortcut…") : symbols)
                .monospaced()
                .frame(minWidth: Dimension.Settings.shortcutWidth)
        }
        .buttonStyle(.bordered)
        .tint(isRecording ? Palette.accent : nil)
        .accessibilityLabel(Text(title))
        .accessibilityValue(isRecording ? Text("Recording") : Text(symbols))
        .accessibilityHint("Records a new key combination. Press Escape to cancel.")
        .onDisappear(perform: stopRecording)
    }

    private func toggleRecording() {
        if isRecording { stopRecording() } else { startRecording() }
    }

    private func startRecording() {
        isRecording = true
        AccessibilityNotification.Announcement(String(localized: "Type the new shortcut")).post()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handle(event)
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        guard let monitor else { return }
        NSEvent.removeMonitor(monitor)
        self.monitor = nil
    }

    private func handle(_ event: NSEvent) {
        guard event.keyCode != KeyCombination.escapeKeyCode else { return stopRecording() }
        guard let combination = KeyCombination(event: event) else { return NSSound.beep() }
        stopRecording()
        record(combination)
    }
}
#endif
