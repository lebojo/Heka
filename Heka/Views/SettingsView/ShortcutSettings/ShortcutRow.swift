#if os(macOS)
import SwiftUI

struct ShortcutRow: View {
    @State private var isRecording = false
    @State private var rejection: ShortcutChange?

    let action: ShortcutAction

    private var store: ShortcutStore { .shared }

    private var rejectionMessage: String? {
        switch rejection {
        case .conflict(let other): String(localized: "Already used by “\(String(localized: other.title))”. Choose another combination.")
        case .missingModifier: String(localized: "Include ⌘, ⌃ or ⌥ in the shortcut.")
        case .saved, nil: nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(action.title)
                Spacer()
                ShortcutRecorder(isRecording: $isRecording, title: action.title,
                                 symbols: store.combination(for: action).symbols, record: record)
                Button("Reset") { apply(store.reset(action)) }
                    .disabled(!store.isCustomized(action))
                    .accessibilityLabel(Text("Reset \(String(localized: action.title))"))
            }
            if let rejectionMessage {
                Label(rejectionMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.textSecondary)
            }
        }
    }

    private func record(_ combination: KeyCombination) {
        apply(store.set(combination, for: action))
    }

    private func apply(_ change: ShortcutChange) {
        rejection = change == .saved ? nil : change
        guard let rejectionMessage else { return }
        AccessibilityNotification.Announcement(rejectionMessage).post()
    }
}
#endif
