import SwiftUI

struct MobileConnectionStatus: View {
    let isConnected: Bool
    let text: String

    var body: some View {
        HStack {
            Image(systemName: isConnected ? "network" : "network.slash")
            Text(text).lineLimit(2)
        }
        .font(Font.caption)
        .padding(Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Material.bar)
    }
}
