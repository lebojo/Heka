import SwiftUI

struct RememberedSheetSize: ViewModifier {
    @Environment(\.sheetSpace) private var space

    @State private var restored = RestoredSheetSize()

    let kind: PreviewSheetKind

    func body(content: Content) -> some View {
        let idealSize = restored.size(of: kind, fitting: space)
        return content
            .frame(minWidth: PreviewSheetKind.minimumSize.width, idealWidth: idealSize.width, maxWidth: .infinity,
                   minHeight: PreviewSheetKind.minimumSize.height, idealHeight: idealSize.height, maxHeight: .infinity)
            .background { SheetResizeObserver(kind: kind) }
    }
}
