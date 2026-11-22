import SwiftUI

struct TypingIndicatorSlot: View {
    let isVisible: Bool

    var body: some View {
        VStack(alignment: .leading) {
            if isVisible {
                TypingIndicator()
                    .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .leading)))
            }
        }
        .animation(.smooth, value: isVisible)
    }
}
