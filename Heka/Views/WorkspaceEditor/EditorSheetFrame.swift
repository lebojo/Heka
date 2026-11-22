import SwiftUI

struct EditorSheetFrame: ViewModifier {
    func body(content: Content) -> some View {
        #if os(macOS)
        content.frame(width: Dimension.Sheet.width)
        #else
        ScrollView { content }.presentationDetents([.medium, .large])
        #endif
    }
}
