import SwiftUI

struct SessionTranscriptRow: View {
    let item: SessionTranscriptItem
    let agent: ConversationAgent?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch item {
            case .message(let message): SessionMessageRow(message: message, agent: agent).equatable()
            case .toolGroup(let run): SessionToolGroup(run: run, agent: agent)
            }
        }
    }
}
