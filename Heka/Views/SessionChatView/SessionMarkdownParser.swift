import Foundation
import Textual

struct SessionMarkdownParser: MarkupParser {
    private let markdown = AttributedStringMarkdownParser(baseURL: nil, options: .init(failurePolicy: .returnPartiallyParsedIfPossible))

    func attributedString(for input: String) throws -> AttributedString {
        let source = SessionTaskList.replacingCheckboxes(in: input)
        let document = (try? markdown.attributedString(for: source)) ?? AttributedString(input)
        return SessionCodeBlockHint.embedding(in: document)
    }
}

struct SessionBlockedImageLoader: AttachmentLoader {
    func attachment(for url: URL, text: String, environment: ColorEnvironmentValues) async throws -> AnyAttachment {
        throw URLError(.cancelled)
    }
}
