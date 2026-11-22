import SwiftUI

struct MobileSessionPlaceholder: View {
    @Binding var settingsVisible: Bool

    let isConnected: Bool

    var body: some View {
        ContentUnavailableView {
            Label(isConnected ? "Choose a Terminal" : "Pick Up on Your Mac", systemImage: "laptopcomputer.and.iphone")
        } description: {
            Text(isConnected ? "Find your projects and sessions in the sidebar." : "Connect to the Mac in Settings to find your projects and sessions.")
        } actions: {
            Button("Connection Settings") { settingsVisible = true }.buttonStyle(.borderedProminent)
        }
        .navigationTitle("Heka")
    }
}
