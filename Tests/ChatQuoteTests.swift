import Foundation

extension ChatJournalTests {
    @MainActor static func composerQuotes() throws {
        let answer = SessionMessage(id: "a1", kind: .assistant, text: "First line\n\nSecond line\n")
        let quote = try ChatQuote(quoting: answer).unwrapped("Assistant messages can be quoted")
        try require(quote.format == .prose && quote.message == "a1" && quote.preview == "First line", "A prose quote keeps its source and previews its first line")
        try require(quote.markdown == "> First line\n>\n> Second line", "Prose is sent as a Markdown blockquote")

        var commented = quote
        commented.comment = "  Why this?  "
        try require(commented.markdown == "Why this?\n\n> First line\n>\n> Second line", "A comment line precedes the quoted snippet")

        let code = ChatQuote(message: "c1", text: "let a = 1\n", format: .code(language: "swift"))
        try require(code.markdown == "```swift\nlet a = 1\n```", "Code is sent as a fenced block with its language")
        let fenced = ChatQuote(message: "c2", text: "````\nx\n````", format: .code(language: nil))
        try require(fenced.markdown == "`````\n````\nx\n````\n`````", "The fence is longer than any backtick run in the code")

        let output = SessionMessage(id: "o1", kind: .tool, text: "Build succeeded", title: "Bash")
        try require(ChatQuote(quoting: output)?.format == .code(language: nil), "Tool output is quoted as code")
        try require(ChatQuote(quoting: SessionMessage(kind: .assistant, text: " \n")) == nil, "Blank messages cannot be quoted")
        let question = SessionMessage(kind: .tool, text: "A", title: "AskUserQuestion", detail: #"{"questions":[{"question":"Q?","header":"H","options":[],"multiSelect":false}]}"#)
        try require(!question.isQuotable, "Questions are not quoted")

        let image = URL(filePath: "/tmp/shot.png")
        let draft = ChatDraft(text: "Fix it", images: [image], quotes: [commented, code])
        try require(!ChatDraft(quotes: [quote]).isBlank, "A quote alone can be sent")
        try require(draft.prompt(for: .claude) == commented.markdown + "\n\n" + code.markdown + "\n\n/tmp/shot.png Fix it",
                    "Quotes precede images and text in the prompt")
        try require(ChatDraft(quotes: [quote]).prompt(for: .codex) == quote.markdown, "A quote without text is sent alone")
        try require(ChatDraft(text: "ls").prompt(for: nil) == "ls", "Drafts without quotes are unchanged")

        let drafts = ChatDrafts()
        let terminal = UUID()
        drafts[terminal: terminal].text = "Fix it"
        drafts.add(quote, to: terminal)
        drafts[terminal: terminal].images = [image]
        let sent = drafts[terminal: terminal]
        drafts.add(code, to: terminal)
        drafts.clear(sent, of: terminal)
        try require(drafts[terminal: terminal] == ChatDraft(quotes: [code]), "Sending keeps quotes added meanwhile")
        drafts.remove(code, from: terminal)
        try require(drafts[terminal: terminal] == ChatDraft(), "A removed quote leaves an empty draft")
        print("PASS composer quotes")
    }
}

private extension Optional {
    func unwrapped(_ message: String) throws -> Wrapped {
        guard let self else { throw NSError(domain: message, code: 1) }
        return self
    }
}
