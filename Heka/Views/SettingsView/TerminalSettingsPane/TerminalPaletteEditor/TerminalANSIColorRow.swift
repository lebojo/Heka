#if os(macOS)
import SwiftUI

struct TerminalANSIColorRow: View {
    @Binding var appearance: TerminalAppearance

    let slots: Range<Int>

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(slots, id: \.self) { slot in
                ColorPicker("ANSI Color \(slot)", selection: $appearance[color: \.ansi[slot]], supportsOpacity: false)
                    .labelsHidden()
            }
        }
    }
}
#endif
