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
    func compactMenuStyle() -> some View { menuStyle(.borderlessButton).fixedSize() }

    func commandInputTraits() -> some View { self }

    func submitsChatMessage(perform submit: @escaping () -> Void) -> some View {
        onSubmit(submit)
            .onKeyPress(.return, phases: .down, action: insertsNewLineOnShiftReturn)
    }

    func previewSheetFrame(_ kind: PreviewSheetKind) -> some View {
        modifier(RememberedSheetSize(kind: kind))
            .presentationSizing(.fitted)
    }
}

@MainActor private func insertsNewLineOnShiftReturn(_ press: KeyPress) -> KeyPress.Result {
    guard press.modifiers == .shift else { return .ignored }
    NSApp.sendAction(#selector(NSText.insertNewlineIgnoringFieldEditor(_:)), to: nil, from: nil)
    return .handled
}
