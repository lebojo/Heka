import SwiftUI

struct DragPreview: View {
    let title: String
    let systemImage: String
    let color: Color
    let colorScheme: ColorScheme

    var body: some View {
        Label {
            Text(title).lineLimit(1).foregroundStyle(Color.textPrimary)
        } icon: {
            Image(systemName: systemImage).foregroundStyle(color)
        }
        .padding(.horizontal, Spacing.m).padding(.vertical, Spacing.s)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: Radius.m))
        .overlay(RoundedRectangle(cornerRadius: Radius.m).strokeBorder(Color.fill, lineWidth: Stroke.hairline))
        .shadow(color: Color.popupShadow, radius: Radius.m, y: Stroke.regular)
        .padding(Spacing.m)
        .environment(\.colorScheme, colorScheme)
    }
}
