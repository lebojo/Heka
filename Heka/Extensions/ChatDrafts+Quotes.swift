import Foundation

extension ChatDrafts {
    func add(_ quote: ChatQuote, to terminal: UUID) {
        self[terminal: terminal].quotes.append(quote)
    }

    func remove(_ quote: ChatQuote, from terminal: UUID) {
        self[terminal: terminal].quotes.removeAll { $0.id == quote.id }
    }
}
