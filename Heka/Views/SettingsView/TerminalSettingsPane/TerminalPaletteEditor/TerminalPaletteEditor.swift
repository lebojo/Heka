import SwiftUI

struct TerminalPaletteEditor: View {
    @Binding var appearance: TerminalAppearance

    var body: some View {
        Group {
            ColorPicker("Background", selection: $appearance[color: \.background], supportsOpacity: false)
            ColorPicker("Text", selection: $appearance[color: \.foreground], supportsOpacity: false)
            ColorPicker("Cursor", selection: $appearance[color: \.cursor], supportsOpacity: false)
            ColorPicker("Selection", selection: $appearance[color: \.selection], supportsOpacity: false)
            LabeledContent("ANSI Colors") { TerminalANSIColorRow(appearance: $appearance, slots: 0..<8) }
            LabeledContent("Bright ANSI Colors") { TerminalANSIColorRow(appearance: $appearance, slots: 8..<16) }
        }
        .disabled(!appearance.isEditable)
    }
}
