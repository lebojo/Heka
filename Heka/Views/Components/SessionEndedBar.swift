import SwiftUI

struct SessionEndedBar<Accessory: View>: View {
    let session: TerminalSession
    let accessory: Accessory
    let reopen: () -> Void

    var body: some View {
        if session.hasExited {
            HStack {
                SessionExitLabel(code: session.exitCode)
                Spacer()
                accessory
                Button("Reopen Terminal", action: reopen)
            }
            .font(Font.callout).padding(Spacing.l).background(Material.bar)
        }
    }
}

extension SessionEndedBar where Accessory == EmptyView {
    init(session: TerminalSession, reopen: @escaping () -> Void) {
        self.init(session: session, accessory: EmptyView(), reopen: reopen)
    }
}
