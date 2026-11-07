import SwiftUI

struct TestFlightSettingsSection: View {
    private let invitationURL = URL(string: "https://testflight.apple.com/join/DsVPEUqk")!

    var body: some View {
        Section {
            Link(destination: invitationURL) {
                Label("TestFlight", systemImage: "airplane")
            }
        } footer: {
            Text("Join the Heka beta on iPhone and iPad.")
        }
    }
}
