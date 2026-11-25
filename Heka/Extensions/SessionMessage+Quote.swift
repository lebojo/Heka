import Foundation

extension SessionMessage {
    var quoteFormat: ChatQuote.Format? {
        switch presentation {
        case .input, .assistant: .prose
        case .tool, .output: .code(language: nil)
        case .question: nil
        }
    }

    var isQuotable: Bool {
        quoteFormat != nil && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
