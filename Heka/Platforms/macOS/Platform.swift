import SwiftUI
import AppKit

@MainActor enum PlatformClipboard {
    static func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

extension Color {
    static let systemTertiaryLabel = Color(nsColor: .tertiaryLabelColor)
    static let systemSurface = Color(nsColor: .textBackgroundColor)
    static let systemControl = Color(nsColor: .controlBackgroundColor)
    static let systemFill = Color(nsColor: .quaternaryLabelColor)
}

extension View {
    func commandInputTraits() -> some View { self }

    func submitsChatMessage(perform submit: @escaping () -> Void) -> some View {
        onSubmit(submit)
    }

    @ViewBuilder func previewSheetFrame(_ kind: PreviewSheetKind) -> some View {
        let framed = modifier(RememberedSheetSize(kind: kind))
        if #available(macOS 15, *) { framed.presentationSizing(.fitted) } else { framed }
    }
}
