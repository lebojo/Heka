#if os(macOS)
import SwiftUI

struct ShortcutSettingsPane: View {
    @State private var isConfirmingRestore = false

    private var store: ShortcutStore { .shared }

    var body: some View {
        Form {
            ForEach(ShortcutArea.allCases) { area in
                Section(String(localized: area.title)) {
                    ForEach(area.actions) { action in
                        ShortcutRow(action: action)
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
