import Foundation

struct ChatDraft: Equatable, Sendable {
    var text = ""
    var images: [URL] = []

    var isBlank: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && images.isEmpty
    }
}
