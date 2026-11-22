import AppKit
import SwiftTerm

extension TerminalView {
    func routeKey(_ event: NSEvent) -> NSEvent? {
        guard !hasMarkedText(), let state = terminalInputStateSnapshot(),
              let route = TerminalKeyRoute(key: event.specialKey, modifiers: event.modifierFlags,
                                           optionAsMeta: UserDefaults.standard.bool(forKey: TerminalKeyRoute.metaKeySetting),
                                           screen: TerminalKeyRoute.Screen(state)) else { return event }
        switch route {
        case .composesCharacter:
            optionAsMetaKey = false
        case .actsAsMeta:
            optionAsMetaKey = true
        case .sends(let bytes):
            guard event.type == .keyDown else { return event }
            send(bytes)
            return nil
        }
        return event
    }
}

private extension TerminalKeyRoute.Screen {
    init(_ state: TerminalInputStateSnapshot) {
        self.init(usesKittyKeyboard: !state.keyboardEnhancementFlags.isEmpty,
                  showsAlternateBuffer: state.isAlternateBuffer,
                  usesApplicationCursor: state.applicationCursor)
    }
}
