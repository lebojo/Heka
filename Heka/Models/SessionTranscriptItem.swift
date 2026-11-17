import Foundation

struct SessionToolRun: Equatable, Sendable {
    let messages: [SessionMessage]

    var title: String? { messages.first?.title }
    var state: SessionMessage.ToolState { messages.last?.displayedToolState ?? .completed }
    var failureCount: Int { messages.filter { $0.displayedToolState == .failed }.count }
    var latestDetail: String? { messages.last { $0.detail?.isEmpty == false }?.detail }
    var memberIDs: [String] { messages.map(\.id) }
}

enum SessionTranscriptItem: Identifiable, Equatable, Sendable {
    case message(SessionMessage)
    case toolGroup(SessionToolRun)

    var id: String {
        switch self {
        case .message(let message): message.id
        case .toolGroup(let run): "group-" + (run.messages.first?.id ?? "")
        }
    }

    static func items(from messages: [SessionMessage]) -> [SessionTranscriptItem] {
        var items: [SessionTranscriptItem] = []
        var run: [SessionMessage] = []
        for message in messages {
            let isTool = message.presentation == .tool
            if isTool, let first = run.first, first.title == message.title {
                run.append(message)
                continue
            }
            items += collapsed(run)
            run = isTool ? [message] : []
            if !isTool { items.append(.message(message)) }
        }
        return items + collapsed(run)
    }

    private static func collapsed(_ run: [SessionMessage]) -> [SessionTranscriptItem] {
        run.count > 1 ? [.toolGroup(SessionToolRun(messages: run))] : run.map(Self.message)
    }
}
