import SwiftUI

struct AboutSettingsSection: View {
    private let websiteURL = URL(string: "https://www.jordan-chap.com")!

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    var body: some View {
        Section {
            Link(destination: websiteURL) {
                Text("Made with ❤️ by Jordan Chap")
            }
            .foregroundStyle(.primary)
        } footer: {
            Text("Version \(version)")
        }
    }
}
