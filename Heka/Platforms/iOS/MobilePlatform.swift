import SwiftUI

@MainActor enum PlatformClipboard {
    static func copy(_ text: String) { UIPasteboard.general.string = text }
}

extension Color {
    static let systemTertiaryLabel = Color(uiColor: .tertiaryLabel)
    static let systemSurface = Color(uiColor: .systemBackground)
    static let systemControl = Color(uiColor: .secondarySystemBackground)
    static let systemFill = Color(uiColor: .quaternaryLabel)
}

extension View {
    func commandInputTraits() -> some View { textInputAutocapitalization(.never) }

    func submitsChatMessage(perform submit: @escaping () -> Void) -> some View { self }

    func previewSheetFrame(_ kind: PreviewSheetKind) -> some View {
        frame(idealWidth: kind.defaultSize.width, idealHeight: kind.defaultSize.height)
    }
}
