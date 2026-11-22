import SwiftUI

struct SessionToolMessage: View {
    @Environment(SessionTranscriptExpansion.self) private var expansion

    let message: SessionMessage

    var body: some View {
        DisclosureGroup(isExpanded: Bindable(expansion)[toolExpanded: message.id]) {
            VStack(alignment: .leading, spacing: Spacing.m) {
                if let detail = message.detail, !detail.isEmpty, detail != message.text {
                    Text(verbatim: detail).font(Font.code).textSelection(.enabled)
                    Divider()
                }
                Text(verbatim: message.text).font(Font.code).textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(Spacing.l)
            .background(Color.fill.opacity(0.3), in: RoundedRectangle(cornerRadius: Radius.m))
        } label: {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Label(message.title ?? String(localized: "Tool"), systemImage: message.displayedToolState.symbol)
                    .font(Font.caption).foregroundStyle(message.displayedToolState.tint)
                if let detail = message.detail, !detail.isEmpty {
                    Text(verbatim: detail).font(Font.code).foregroundStyle(Color.textSecondary)
                        .lineLimit(2).frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}
