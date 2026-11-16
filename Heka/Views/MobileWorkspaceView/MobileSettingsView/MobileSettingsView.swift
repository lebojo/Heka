import SwiftUI

struct MobileSettingsView: View {
    @AppStorage("mobileSessionDisplayMode") private var mode: SessionDisplayMode = .chat

    @Environment(\.dismiss) private var dismiss

    @State private var scannerVisible = false

    let store: MobileWorkspaceStore

    var body: some View {
        NavigationStack {
            Form {
                SessionDisplaySettingsSection(mode: $mode)
                MobileTerminalSettingsSection()
                MobileSavedHostsSection(scannerVisible: $scannerVisible)
                MobileManualHostSection()
                TestFlightSettingsSection()
                AboutSettingsSection()
            }
            .environment(store)
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .sheet(isPresented: $scannerVisible) {
            MobileScannerSheet().environment(store)
        }
    }
}
