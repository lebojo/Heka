import Foundation

enum SessionCodeTokens {
    enum Kind { case comment, string, number, keyword, addition, deletion }
    struct Token {
        let range: NSRange
        let kind: Kind
    }

    private static let keywords = "actor|as|async|await|break|case|catch|class|const|continue|def|defer|do|else|enum|export|extension|false|final|for|from|func|function|guard|if|import|in|init|interface|is|let|match|new|nil|nonisolated|null|override|private|protocol|public|return|self|some|static|struct|super|switch|throw|throws|true|try|type|var|void|while|with|yield"
    private static let patterns: [String: NSRegularExpression] = {
        let strings = #"("(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|`(?:\\.|[^`\\])*`)"#
        let numbers = #"(\b(?:0[xX][0-9a-fA-F]+|\d+(?:\.\d+)?)\b)"#
        let words = "(\\b(?:" + keywords + ")\\b)"
        return ["slash": #"(//[^\n]*|/\*[\s\S]*?\*/)"#, "hash": #"(#[^\n]*)"#, "none": "((?!))"].compactMapValues {
            try? NSRegularExpression(pattern: [$0, strings, numbers, words].joined(separator: "|"))
        }
    }()

    static func parse(_ code: String, language: String) -> [Token] {
        let language = language.lowercased()
        let range = NSRange(code.startIndex..., in: code)
        if ["diff", "patch"].contains(language) {
            guard let expression = try? NSRegularExpression(pattern: #"^[+-].*$"#, options: [.anchorsMatchLines]) else { return [] }
            return expression.matches(in: code, range: range).map {
                Token(range: $0.range, kind: (code as NSString).substring(with: $0.range).hasPrefix("+") ? .addition : .deletion)
            }
        }
        let hash = ["sh", "bash", "zsh", "shell", "python", "py", "ruby", "rb", "yaml", "yml", "toml"].contains(language)
        let slash = ["swift", "js", "javascript", "ts", "typescript", "tsx", "jsx", "c", "cpp", "c++", "cs", "csharp", "java", "kotlin", "kt", "go", "rust", "rs", "css", "scss", "jsonc"].contains(language)
        guard hash || slash || language == "json", let expression = patterns[hash ? "hash" : slash ? "slash" : "none"] else { return [] }
        let kinds: [Kind] = [.comment, .string, .number, .keyword]
        return expression.matches(in: code, range: range).compactMap { match in
            guard let index = (1...4).first(where: { match.range(at: $0).location != NSNotFound }) else { return nil }
            return Token(range: match.range, kind: kinds[index - 1])
        }
    }
}
