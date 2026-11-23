import Foundation
import Observation

@MainActor @Observable final class ChatDrafts {
    private var drafts: [UUID: ChatDraft] = [:]

    subscript(terminal terminal: UUID) -> ChatDraft {
        get { drafts[terminal] ?? ChatDraft() }
        set { drafts[terminal] = newValue == ChatDraft() ? nil : newValue }
    }

    func take(from terminal: UUID) -> ChatDraft {
        let draft = self[terminal: terminal]
        self[terminal: terminal] = ChatDraft()
        return draft
    }

    func restore(_ unsent: ChatDraft, to terminal: UUID) {
        let typed = self[terminal: terminal].renumberingPastes(after: unsent)
        self[terminal: terminal] = ChatDraft(text: [unsent.text, typed.text].filter { !$0.isEmpty }.joined(separator: "\n"),
                                             images: unsent.images + typed.images,
                                             pastes: unsent.pastes + typed.pastes,
                                             quotes: unsent.quotes + typed.quotes)
    }

    func remove(_ image: URL, from terminal: UUID) {
        self[terminal: terminal].images.removeAll { $0 == image }
        Task { await ComposerImageStore.discard(image) }
    }
}
