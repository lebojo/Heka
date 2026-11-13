import Foundation

struct SessionCodeBlockHint: Hashable, Sendable {
    private final class Entry: Sendable {
        let hint: String
        let block: SessionCodeBlockHint?

        init(hint: String, block: SessionCodeBlockHint?) {
            self.hint = hint
            self.block = block
        }

        var cost: Int { hint.utf8.count + (block?.code.utf8.count ?? 0) }
    }

    private static let marker = " heka-"
    private static let separator = "\u{0}"
    nonisolated(unsafe) private static let byHint: NSCache<NSString, Entry> = cache()
    nonisolated(unsafe) private static let byBlock: NSCache<NSNumber, Entry> = cache()

    let language: String
    let code: String

    init(language: String, code: String) {
        self.language = language
        self.code = code
    }

    init?(hint: String?) {
        guard let hint, let range = hint.range(of: Self.marker, options: .backwards) else { return nil }
        let entry = Self.byHint.object(forKey: hint as NSString) ?? Self.decodedEntry(for: hint, payload: String(hint[range.upperBound...]))
        guard let block = entry.block else { return nil }
        self = block
    }

    var encoded: String {
        let key = NSNumber(value: hashValue)
        if let entry = Self.byBlock.object(forKey: key), entry.block == self { return entry.hint }
        let payload = language + Self.separator + code
        let entry = Entry(hint: (language.isEmpty ? "text" : language) + Self.marker + Data(payload.utf8).base64EncodedString(), block: self)
        Self.byHint.setObject(entry, forKey: entry.hint as NSString, cost: entry.cost)
        Self.byBlock.setObject(entry, forKey: key, cost: entry.cost)
        return entry.hint
    }

    private static func cache<Key>() -> NSCache<Key, Entry> {
        let cache = NSCache<Key, Entry>()
        cache.countLimit = 512
        cache.totalCostLimit = 16_777_216
        return cache
    }

    private static func decodedEntry(for hint: String, payload: String) -> Entry {
        let entry = Entry(hint: hint, block: decode(payload))
        byHint.setObject(entry, forKey: hint as NSString, cost: entry.cost)
        return entry
    }

    private static func decode(_ payload: String) -> SessionCodeBlockHint? {
        guard let data = Data(base64Encoded: payload), let text = String(data: data, encoding: .utf8),
              let split = text.range(of: separator) else { return nil }
        return SessionCodeBlockHint(language: String(text[..<split.lowerBound]), code: String(text[split.upperBound...]))
    }

    static func embedding(in document: AttributedString) -> AttributedString {
        var result = document
        var blocks: [Int: (range: Range<AttributedString.Index>, language: String)] = [:]
        for (intent, range) in document.runs[\.presentationIntent] {
            guard let component = intent?.components.first(where: \.kind.isCodeBlock),
                  case .codeBlock(let language) = component.kind else { continue }
            let lower = blocks[component.identity]?.range.lowerBound ?? range.lowerBound
            blocks[component.identity] = (lower..<range.upperBound, language ?? "")
        }
        for (identity, block) in blocks {
            var code = String(document[block.range].characters)
            if code.hasSuffix("\n") { code.removeLast() }
            let hint = Self(language: block.language, code: code).encoded
            for (intent, range) in document[block.range].runs[\.presentationIntent] {
                result[range].presentationIntent = intent?.replacingCodeBlockHint(identity: identity, with: hint)
            }
        }
        return result
    }
}

private extension PresentationIntent.Kind {
    var isCodeBlock: Bool {
        if case .codeBlock = self { true } else { false }
    }
}

private extension PresentationIntent {
    func replacingCodeBlockHint(identity: Int, with hint: String) -> PresentationIntent? {
        components.reversed().reduce(nil) { parent, component in
            let kind: Kind = component.kind.isCodeBlock && component.identity == identity ? .codeBlock(languageHint: hint) : component.kind
            return PresentationIntent(kind, identity: component.identity, parent: parent)
        }
    }
}
