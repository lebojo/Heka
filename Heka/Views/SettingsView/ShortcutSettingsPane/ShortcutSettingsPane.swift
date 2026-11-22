#if os(macOS)
import SwiftUI

struct ShortcutSettingsPane: View {
    @State private var isConfirmingRestore = false
    @State private var recordingAction: ShortcutAction?

    private var store: ShortcutStore { .shared }

    var body: some View {
        Form {
            ForEach(ShortcutArea.allCases) { area in
                Section(String(localized: area.title)) {
                    ForEach(area.actions) { action in
                        ShortcutRow(recordingAction: $recordingAction, action: action)
                    }
                }
            }
            Section {
                HStack {
                    Spacer()
                    Button("Restore Defaults") { isConfirmingRestore = true }
                        .disabled(!store.hasOverrides)
                }
            }
        }
        .formStyle(.grouped)
        .confirmationDialog("Restore all keyboard shortcuts to their defaults?", isPresented: $isConfirmingRestore) {
            Button("Restore Defaults", role: .destructive) { store.restoreDefaults() }
        }
    }
}
#endif
