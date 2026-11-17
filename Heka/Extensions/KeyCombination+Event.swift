#if os(macOS)
import AppKit

extension KeyCombination {
    static let escapeKeyCode: UInt16 = 53

    private static let namedKeyCodes: [UInt16: NamedKey] = [
        36: .returnKey, 76: .returnKey, 48: .tab, 49: .space, 51: .delete,
        126: .upArrow, 125: .downArrow, 123: .leftArrow, 124: .rightArrow,
    ]

    init?(event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        var modifiers: Modifiers = []
        if flags.contains(.command) { modifiers.insert(.command) }
        if flags.contains(.shift) { modifiers.insert(.shift) }
        if flags.contains(.option) { modifiers.insert(.option) }
        if flags.contains(.control) { modifiers.insert(.control) }
        if let named = Self.namedKeyCodes[event.keyCode] {
            self.init(.named(named), modifiers: modifiers)
            return
        }
        guard let characters = event.characters(byApplyingModifiers: []), characters.count == 1,
              let character = characters.first, !character.isWhitespace, !character.isNewline,
              character.unicodeScalars.allSatisfy({ $0.value < 0xF700 }) else { return nil }
        self.init(character, modifiers: modifiers)
    }
}
#endif
