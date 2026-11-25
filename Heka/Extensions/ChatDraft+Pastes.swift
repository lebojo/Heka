import Foundation

extension ChatDraft {
    var editedText: String {
        get { text }
        set { edit(newValue) }
    }

    var visiblePastes: [ChatPaste] {
        pastes.filter { text.contains($0.token) }
    }

    var message: String {
        var message = ""
        var rest = text[...]
        while let (paste, range) = firstToken(in: rest) {
            message += rest[..<range.lowerBound] + paste.text
            rest = rest[range.upperBound...]
        }
        return message + rest
    }

    mutating func edit(_ newText: String) {
        let previous = text
        text = newText
        guard let inserted = Self.insertion(from: previous, to: newText), ChatPaste.isLarge(newText[inserted]) else { return }
        let paste = ChatPaste(text: String(newText[inserted]), excluding: newText)
        text.replaceSubrange(inserted, with: paste.token)
        pastes.removeAll { $0.token == paste.token }
        pastes.append(paste)
    }

    mutating func removePaste(_ paste: ChatPaste) {
        text = text.replacing(paste.token, with: "")
        pastes.removeAll { $0.id == paste.id }
    }

    func renumberingPastes(after earlier: ChatDraft) -> ChatDraft {
        let usedText = earlier.text + earlier.pastes.map(\.token).joined()
        var draft = self
        for index in draft.pastes.indices where usedText.contains(draft.pastes[index].token) {
            let paste = draft.pastes[index]
            let renumbered = ChatPaste(text: paste.text, excluding: usedText + draft.text)
            draft.text = draft.text.replacing(paste.token, with: renumbered.token)
            draft.pastes[index] = renumbered
        }
        return draft
    }

    private func firstToken(in text: Substring) -> (ChatPaste, Range<Substring.Index>)? {
        pastes
            .compactMap { paste in text.range(of: paste.token).map { (paste, $0) } }
            .min { $0.1.lowerBound < $1.1.lowerBound }
    }

    private static func insertion(from old: String, to new: String) -> Range<String.Index>? {
        guard new.utf8.count >= ChatPaste.minimumLines - 1, new != old else { return nil }
        let oldCharacters = Array(old), newCharacters = Array(new)
        let prefix = zip(oldCharacters, newCharacters).prefix { $0 == $1 }.count
        let available = min(oldCharacters.count, newCharacters.count) - prefix
        let suffix = zip(oldCharacters.reversed(), newCharacters.reversed()).prefix(available).prefix { $0 == $1 }.count
        let start = new.index(new.startIndex, offsetBy: prefix)
        let end = new.index(new.endIndex, offsetBy: -suffix)
        return start < end ? start..<end : nil
    }
}
