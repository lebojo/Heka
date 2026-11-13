import SwiftUI

struct AgentLogo: View {
    let agent: ConversationAgent
    let size: CGFloat

    var body: some View {
        agent.logo.resizable().scaledToFit()
            .frame(width: size, height: size)
    }
}
