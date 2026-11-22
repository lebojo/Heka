import Foundation

struct TerminalMirrorAttributes: Equatable {
    private enum Slot: Int, CaseIterable {
        case bold, dim, italic, underline, blink, inverse, invisible, crossedOut, foreground, background, underlineColor
    }

    private static let styles: [Int: Slot] = [1: .bold, 2: .dim, 3: .italic, 5: .blink, 7: .inverse, 8: .invisible, 9: .crossedOut]
    private static let resets: [Int: [Slot]] = [
        22: [.bold, .dim], 23: [.italic], 24: [.underline], 25: [.blink], 27: [.inverse], 28: [.invisible], 29: [.crossedOut],
        39: [.foreground], 49: [.background], 59: [.underlineColor],
    ]
    private static let extendedColors: [Int: Slot] = [38: .foreground, 48: .background, 58: .underlineColor]

    private var slots: [Slot: String] = [:]

    var sequence: String {
        let codes = Slot.allCases.compactMap { slots[$0] }
        return "\u{1b}[" + (["0"] + codes).joined(separator: ";") + "m"
    }

    mutating func apply(_ parameters: String) {
        let tokens = parameters.split(separator: ";", omittingEmptySubsequences: false).map(String.init)
        var index = 0
        while index < tokens.count {
            index += apply(tokens, at: index)
        }
    }

    private mutating func apply(_ tokens: [String], at index: Int) -> Int {
        let token = tokens[index]
        let code = Int(token.prefix { $0 != ":" }) ?? 0
        if let slot = Self.extendedColors[code] { return applyColor(tokens, at: index, to: slot) }
        switch code {
        case 0: slots = [:]
        case 4: applyUnderline(token)
        case 21: slots[.underline] = "21"
        case 30...37, 90...97: slots[.foreground] = "\(code)"
        case 40...47, 100...107: slots[.background] = "\(code)"
        default:
            if let slot = Self.styles[code] { slots[slot] = "\(code)" }
            for slot in Self.resets[code] ?? [] { slots[slot] = nil }
        }
        return 1
    }

    private mutating func applyUnderline(_ token: String) {
        let parts = token.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count > 1 else { slots[.underline] = "4"; return }
        let style = Int(parts[1]) ?? 0
        slots[.underline] = style == 0 ? nil : "4:\(style)"
    }

    private mutating func applyColor(_ tokens: [String], at index: Int, to slot: Slot) -> Int {
        let token = tokens[index]
        if token.contains(":") {
            let parts = token.split(separator: ":", omittingEmptySubsequences: false).dropFirst().map(String.init)
            if Self.colorLength(kind: parts.first).map({ parts.count >= $0 - 1 }) == true { slots[slot] = token }
            return 1
        }
        let consumed = min(2, tokens.count - index)
        guard consumed == 2, let length = Self.colorLength(kind: tokens[index + 1]), index + length <= tokens.count else { return consumed }
        slots[slot] = tokens[index..<(index + length)].joined(separator: ";")
        return length
    }

    private static func colorLength(kind: String?) -> Int? {
        switch kind {
        case "2": 5
        case "5": 3
        default: nil
        }
    }
}
