import AppKit
import SwiftUI

struct RememberedSheetSize: ViewModifier {
    @State private var idealSize: CGSize

    let kind: PreviewSheetKind

    init(kind: PreviewSheetKind) {
        let defaults = UserDefaults.standard
        _idealSize = State(initialValue: kind.restoredSize(width: defaults.double(forKey: kind.widthKey),
                                                           height: defaults.double(forKey: kind.heightKey),
                                                           fitting: Self.availableSize))
        self.kind = kind
    }

    private static var availableSize: CGSize? {
        guard let parent = NSApp.keyWindow ?? NSApp.mainWindow, let screen = parent.screen ?? NSScreen.main else { return nil }
        let titleBarHeight = parent.frame.height - parent.contentLayoutRect.height
        return CGSize(width: screen.visibleFrame.width, height: screen.visibleFrame.height - titleBarHeight)
    }

    func body(content: Content) -> some View {
        content
            .frame(minWidth: PreviewSheetKind.minimumSize.width, idealWidth: idealSize.width, maxWidth: .infinity,
                   minHeight: PreviewSheetKind.minimumSize.height, idealHeight: idealSize.height, maxHeight: .infinity)
            .background { SheetResizeObserver(kind: kind, initialSize: idealSize) }
    }
}
