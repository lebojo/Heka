import SwiftUI

struct MobileSidebarPlaceholder: View {
    @Binding var settingsVisible: Bool

    let isEmpty: Bool
    let isConnected: Bool
    let hasNoResults: Bool
    let search: String

    var body: some View {
        if isEmpty {
            ContentUnavailableView {
                Label(isConnected ? "No Projects" : "Your Mac, Within Reach", systemImage: "laptopcomputer.and.iphone")
            } description: {
                Text(isConnected ? "Add a project in Heka on the Mac." : "Connect to the local network to continue a session.")
            } actions: {
                Button("Connect") { settingsVisible = true }.buttonStyle(.borderedProminent)
            }
        } else if hasNoResults {
            ContentUnavailableView.search(text: search)
        }
    }
}
