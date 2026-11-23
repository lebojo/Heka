extension ChatDraft {
    func prompt(for agent: ConversationAgent?) -> String {
        let request = agent?.prompt(message, attaching: images) ?? message
        return (quotes.map(\.markdown) + [request]).filter { !$0.isEmpty }.joined(separator: "\n\n")
    }
}
