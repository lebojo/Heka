import Foundation

struct ChatDraft: Equatable, Sendable {
    var text = ""
    var images: [URL] = []
    var pastes: [ChatPaste] = []
    var quotes: [ChatQuote] = []

    var isBlank: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && images.isEmpty && quotes.isEmpty
    }
}
