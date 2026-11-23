import Foundation

struct ChatPaste: Equatable, Identifiable, Sendable {
    static let minimumLines = 10
    static let minimumCharacters = 2000

    let id: UUID
    let token: String
    let text: String

    var markdown: String {
        let longestRun = text.split(whereSeparator: { $0 != "`" }).map(\.count).max() ?? 0
        let fence = String(repeating: "`", count: max(3, longestRun + 1))
        return fence + "\n" + text + "\n" + fence
    }

    init(text: String, excluding usedText: String) {
        id = UUID()
        self.text = text
        token = Self.token(lines: Self.lineCount(of: text), excluding: usedText)
    }

    static func isLarge(_ text: some StringProtocol) -> Bool {
        text.count >= minimumCharacters || lineCount(of: text) >= minimumLines
    }

    static func lineCount(of text: some StringProtocol) -> Int {
        let breaks = text.reduce(0) { $1.isNewline ? $0 + 1 : $0 }
        return text.last?.isNewline == false ? breaks + 1 : breaks
    }

    private static func token(lines: Int, excluding usedText: String) -> String {
        let label = String(localized: "Pasted ~\(lines) lines", comment: "Placeholder for a large paste in the chat composer")
        let token = "[\(label)]"
        guard usedText.contains(token) else { return token }
        let number = (2...).first { !usedText.contains("[\(label) #\($0)]") } ?? 2
        return "[\(label) #\(number)]"
    }
}
