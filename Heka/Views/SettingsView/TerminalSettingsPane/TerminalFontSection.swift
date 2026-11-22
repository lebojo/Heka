#if os(macOS)
import AppKit
import SwiftUI

struct TerminalFontSection: View {
    @State private var families = MonospacedFonts.families

    @Binding var appearance: TerminalAppearance

    var body: some View {
        Section("Font") {
            Picker("Font", selection: $appearance.fontFamily) {
                Text("System").tag("")
                Divider()
                ForEach(families, id: \.self) { family in
                    Text(family).tag(family)
                }
            }
            Stepper(value: $appearance.fontSize, in: TerminalAppearance.fontSizes) {
                LabeledContent("Size", value: "\(Int(appearance.fontSize)) pt")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSFont.fontSetChangedNotification)) { _ in
            families = MonospacedFonts.reload()
        }
    }
}
#endif
