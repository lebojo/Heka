import Foundation

struct ChatQuote: Identifiable, Equatable, Sendable {
    enum Format: Equatable, Sendable {
        case prose
        case code(language: String?)
    }

    let id: UUID
    let message: SessionMessage.ID
    let text: String
    let format: Format
    var comment: String

    init(id: UUID = UUID(), message: SessionMessage.ID, text: String, format: Format, comment: String = "") {
        self.id = id
        self.message = message
        self.text = text
        self.format = format
        self.comment = comment
    }

    init?(quoting message: SessionMessage, comment: String = "") {
        guard message.isQuotable, let format = message.quoteFormat else { return nil }
        self.init(message: message.id, text: message.text, format: format, comment: comment)
    }

    var preview: String {
        lines.lazy.map { $0.trimmingCharacters(in: .whitespaces) }.first { !$0.isEmpty } ?? ""
    }

    var note: String {
        comment.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var markdown: String {
        note.isEmpty ? quotedText : note + "\n\n" + quotedText
    }

    private var snippet: String {
        text.trimmingCharacters(in: .newlines)
    }

    private var lines: [Substring] {
        snippet.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
    }

    private var quotedText: String {
        switch format {
        case .prose:
            return lines.map { $0.isEmpty ? ">" : "> " + $0 }.joined(separator: "\n")
        case .code(let language):
            let fence = String(repeating: "`", count: max(3, longestBacktickRun + 1))
            return fence + (language ?? "") + "\n" + snippet + "\n" + fence
        }
    }

    private var longestBacktickRun: Int {
        snippet.split(whereSeparator: { $0 != "`" }).map(\.count).max() ?? 0
    }
}
