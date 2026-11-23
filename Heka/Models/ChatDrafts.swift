import Foundation
import Observation

@MainActor @Observable final class ChatDrafts {
    private var drafts: [UUID: ChatDraft] = [:]

    subscript(terminal terminal: UUID) -> ChatDraft {
        get { drafts[terminal] ?? ChatDraft() }
        set { drafts[terminal] = newValue == ChatDraft() ? nil : newValue }
    }

    func clear(_ sent: ChatDraft, of terminal: UUID) {
        var draft = self[terminal: terminal]
        if draft.text == sent.text { draft.text = "" }
        if draft.images == sent.images { draft.images = [] }
        draft.quotes.removeAll(where: sent.quotes.contains)
        self[terminal: terminal] = draft
    }

    func remove(_ image: URL, from terminal: UUID) {
        self[terminal: terminal].images.removeAll { $0 == image }
        Task { await ComposerImageStore.discard(image) }
    }
}
