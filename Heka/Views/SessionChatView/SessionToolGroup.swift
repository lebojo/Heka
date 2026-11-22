import SwiftUI

struct SessionToolGroup: View {
    @Environment(SessionTranscriptExpansion.self) private var expansion

    let run: SessionToolRun
    let agent: ConversationAgent?

    var body: some View {
        DisclosureGroup(isExpanded: Bindable(expansion)[groupExpanded: run.memberIDs]) {
            LazyVStack(alignment: .leading, spacing: Spacing.m) {
                ForEach(run.messages) { SessionMessageRow(message: $0, agent: agent).equatable() }
            }
            .padding(.leading, Spacing.l)
        } label: {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.s) {
                    Label {
                        Text(verbatim: "\(run.title ?? String(localized: "Tool")) (\(run.messages.count))")
                    } icon: {
                        Image(systemName: run.state.symbol)
                    }
                    .foregroundStyle(run.state.tint)
                    if run.failureCount > 0, run.state != .failed {
                        Label {
                            Text(verbatim: "\(run.failureCount)")
                        } icon: {
                            Image(systemName: SessionMessage.ToolState.failed.symbol)
                        }
                        .foregroundStyle(SessionMessage.ToolState.failed.tint)
                        .accessibilityLabel("Failed Calls")
                        .accessibilityValue(Text(verbatim: "\(run.failureCount)"))
                    }
                }
                .font(Font.caption)
                if let detail = run.latestDetail {
                    Text(verbatim: detail).font(Font.code).foregroundStyle(Color.textSecondary)
                        .lineLimit(2).frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}
