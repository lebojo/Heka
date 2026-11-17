import SwiftUI

extension KeyCombination {
    var keyboardShortcut: KeyboardShortcut {
        KeyboardShortcut(keyEquivalent, modifiers: eventModifiers)
    }

    private var keyEquivalent: KeyEquivalent {
        switch key {
        case .character(let character): KeyEquivalent(character)
        case .named(.returnKey): .return
        case .named(.tab): .tab
        case .named(.space): .space
        case .named(.delete): .delete
        case .named(.upArrow): .upArrow
        case .named(.downArrow): .downArrow
        case .named(.leftArrow): .leftArrow
        case .named(.rightArrow): .rightArrow
        }
    }

    private var eventModifiers: EventModifiers {
        var result: EventModifiers = []
        if modifiers.contains(.command) { result.insert(.command) }
        if modifiers.contains(.shift) { result.insert(.shift) }
        if modifiers.contains(.option) { result.insert(.option) }
        if modifiers.contains(.control) { result.insert(.control) }
        return result
    }
}

extension ShortcutAction {
    @MainActor var symbols: String { ShortcutStore.shared.combination(for: self).symbols }
}

extension View {
    func keyboardShortcut(_ action: ShortcutAction) -> some View {
        keyboardShortcut(ShortcutStore.shared.combination(for: action).keyboardShortcut)
    }
}
