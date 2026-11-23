import Foundation

struct PendingChatMessage: Identifiable, Equatable, Sendable {
    enum State: Equatable, Sendable {
        case sending, unconfirmed
    }

    let id: UUID
    let text: String
    let prompt: String
    var state: State = .sending
    var followsUnmatchedInput = false

    init(id: UUID = UUID(), text: String, prompt: String) {
        self.id = id
        self.text = Self.normalized(text).isEmpty ? prompt : text
        self.prompt = prompt
    }

    init?(text: String, prompt: String, agent: ConversationAgent?) {
        guard agent == nil || !text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("/") else { return nil }
        self.init(text: text, prompt: prompt)
    }

    func matches(_ input: String) -> Bool {
        let input = Self.normalized(input)
        let typed = Self.normalized(text)
        return input == Self.normalized(prompt) || (!typed.isEmpty && input.hasSuffix(typed))
    }

    private static func normalized(_ text: String) -> String {
        text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}

struct PendingChatMessages: Sendable {
    static let confirmationGrace: Duration = .seconds(15)

    private(set) var items: [PendingChatMessage] = []
    private var knownInputs: Set<String> = []

    mutating func add(_ message: PendingChatMessage) {
        items.append(message)
    }

    mutating func remove(_ id: UUID) {
        items.removeAll { $0.id == id }
    }

    mutating func markUnconfirmed(_ ids: [UUID]) {
        items.removeAll { ids.contains($0.id) && $0.followsUnmatchedInput }
        for index in items.indices where ids.contains(items[index].id) {
            items[index].state = .unconfirmed
        }
    }

    mutating func reconcile(with messages: [SessionMessage]) {
        let inputs = messages.filter { $0.kind == .input }
        let fresh = inputs.filter { !knownInputs.contains($0.id) }
        knownInputs = Set(inputs.map(\.id))
        guard !items.isEmpty, !fresh.isEmpty else { return }
        var matchedAny = false
        for input in fresh {
            guard let index = items.firstIndex(where: { $0.matches(input.text) }) else { continue }
            items.removeFirst(index + 1)
            matchedAny = true
        }
        if !matchedAny, fresh.count == 1, fresh.last?.id == inputs.last?.id, items.first?.state == .sending {
            items[0].followsUnmatchedInput = true
        }
    }
}
