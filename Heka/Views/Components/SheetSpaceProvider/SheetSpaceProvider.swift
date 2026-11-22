#if os(macOS)
import SwiftUI

struct SheetSpaceProvider: ViewModifier {
    @State private var space: CGSize?

    func body(content: Content) -> some View {
        content
            .environment(\.sheetSpace, space)
            .background { SheetSpaceReader(space: $space) }
    }
}
#endif
