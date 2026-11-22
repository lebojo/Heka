import SwiftUI

struct SessionSendButton: View {
    let isSending: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isSending { ProgressView().controlSize(.mini) }
                else { Image(systemName: "arrow.up").font(Font.label.weight(.semibold)) }
            }
            .frame(width: Dimension.Chat.sendSize, height: Dimension.Chat.sendSize)
            .contentShape(.circle)
        }
        .buttonStyle(.borderedProminent).buttonBorderShape(.circle)
        .controlSize(.small)
        .accessibilityLabel("Send to Session")
        .help("Send to Session")
    }
}
