import SwiftUI

struct SessionTranscriptList: View {
    @State private var followsLatest = true
    @State private var lastContentOrigin: CGFloat?
    @State private var expansion = SessionTranscriptExpansion()
    @State private var items: [SessionTranscriptItem] = []

    let messages: [SessionMessage]
    let pending: [PendingChatMessage]
    let source: SessionChatSource
    let showsTypingIndicator: Bool

    var body: some View {
        GeometryReader { viewport in
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: Spacing.xxl) {
                        if messages.isEmpty && pending.isEmpty {
                            ContentUnavailableView(source.agent.map { "\($0.title) Conversation" } ?? "The Session Is Ready",
                                                   systemImage: "bubble.left.and.bubble.right",
                                                   description: Text(source.agent == nil ? "Write to continue working on the Mac." : "Messages from this session will appear here. Interactive menus are available in Terminal."))
                        }
                        ForEach(items) { item in
                            SessionTranscriptRow(item: item, agent: source.agent)
                        }
                        ForEach(pending) { message in
                            SessionPendingMessage(message: message)
                        }
                        TypingIndicatorSlot(isVisible: showsTypingIndicator)
                        Color.clear.frame(height: 1).id("latest")
                    }
                    .frame(maxWidth: Dimension.Chat.readableWidth)
                    .padding(Spacing.xl)
                    .frame(maxWidth: .infinity)
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("transcript")) } action: { frame in
                        if lastContentOrigin == nil || abs((lastContentOrigin ?? 0) - frame.minY) > 0.5 {
                            followsLatest = frame.maxY <= viewport.size.height + 60
                        }
                        lastContentOrigin = frame.minY
                    }
                }
                .coordinateSpace(.named("transcript"))
                .defaultScrollAnchor(.bottom)
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: messages, initial: true) { items = SessionTranscriptItem.items(from: messages) }
                .onChange(of: messages) { old, _ in
                    if old.isEmpty || followsLatest { proxy.scrollTo("latest", anchor: .bottom) }
                }
                .onChange(of: pending) { old, new in
                    if new.count > old.count { followsLatest = true; proxy.scrollTo("latest", anchor: .bottom) }
                }
                .onChange(of: showsTypingIndicator) { if followsLatest { proxy.scrollTo("latest", anchor: .bottom) } }
                .onChange(of: viewport.size.height) { if followsLatest { proxy.scrollTo("latest", anchor: .bottom) } }
                .overlay(alignment: .bottomTrailing) {
                    if !followsLatest {
                        Button { followsLatest = true; proxy.scrollTo("latest", anchor: .bottom) } label: {
                            Label("Latest Messages", systemImage: "arrow.down")
                        }.buttonStyle(.borderedProminent).font(Font.caption).padding()
                    }
                }
            }
        }
        .environment(expansion)
    }
}
