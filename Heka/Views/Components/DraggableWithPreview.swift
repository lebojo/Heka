import SwiftUI

struct DraggableWithPreview: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    let payload: String
    let title: String
    let systemImage: String
    let color: Color

    func body(content: Content) -> some View {
        content.draggable(payload) {
            DragPreview(title: title, systemImage: systemImage, color: color, colorScheme: colorScheme)
        }
    }
}

extension View {
    func draggable(_ payload: String, title: String, systemImage: String, color: Color) -> some View {
        modifier(DraggableWithPreview(payload: payload, title: title, systemImage: systemImage, color: color))
    }
}
