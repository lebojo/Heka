import Foundation

struct KeyCombination: Codable, Hashable, Sendable {
    struct Modifiers: OptionSet, Codable, Hashable, Sendable {
        let rawValue: Int

        static let control = Modifiers(rawValue: 1 << 0)
        static let option = Modifiers(rawValue: 1 << 1)
        static let shift = Modifiers(rawValue: 1 << 2)
        static let command = Modifiers(rawValue: 1 << 3)
    }

    enum NamedKey: String, Codable, Hashable, Sendable, CaseIterable {
        case returnKey = "return"
        case tab
        case space
        case delete
        case upArrow = "up"
        case downArrow = "down"
        case leftArrow = "left"
        case rightArrow = "right"

        var symbol: String {
            switch self {
            case .returnKey: "↩"
            case .tab: "⇥"
            case .space: "Space"
            case .delete: "⌫"
            case .upArrow: "↑"
            case .downArrow: "↓"
            case .leftArrow: "←"
            case .rightArrow: "→"
            }
        }
    }

    enum Key: Codable, Hashable, Sendable {
        case character(Character)
        case named(NamedKey)

        private var storedValue: String {
            switch self {
            case .character(let character): String(character)
            case .named(let named): named.rawValue
            }
        }

        var symbol: String {
            switch self {
            case .character(let character): String(character).uppercased()
            case .named(let named): named.symbol
            }
        }

        init(from decoder: Decoder) throws {
            let value = try decoder.singleValueContainer().decode(String.self)
            if let named = NamedKey(rawValue: value) { self = .named(named) }
            else if value.count == 1, let character = value.first { self = .character(character) }
            else { throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown key \(value)")) }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(storedValue)
        }
    }

    let key: Key
    let modifiers: Modifiers

    init(_ key: Key, modifiers: Modifiers = .command) {
        self.key = key
        self.modifiers = modifiers
    }

    init(_ character: Character, modifiers: Modifiers = .command) {
        self.init(.character(Character(character.lowercased())), modifiers: modifiers)
    }

    var hasCommandModifier: Bool {
        !modifiers.isDisjoint(with: [.command, .control, .option])
    }

    var symbols: String {
        let ordered: [(Modifiers, String)] = [(.control, "⌃"), (.option, "⌥"), (.shift, "⇧"), (.command, "⌘")]
        return ordered.filter { modifiers.contains($0.0) }.map(\.1).joined() + key.symbol
    }
}
