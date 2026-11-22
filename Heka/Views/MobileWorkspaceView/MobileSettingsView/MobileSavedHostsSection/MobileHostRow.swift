import SwiftUI

struct MobileHostRow: View {
    let host: SavedHost
    let isSelected: Bool

    var body: some View {
        HStack {
            Label {
                VStack(alignment: .leading) {
                    Text(host.name).foregroundStyle(Color.textPrimary)
                    Text(host.summary).font(Font.caption).foregroundStyle(Color.textSecondary)
                }
            } icon: { Image(systemName: "desktopcomputer") }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark").foregroundStyle(Color.accentColor).accessibilityLabel("Selected")
            }
        }
    }
}
