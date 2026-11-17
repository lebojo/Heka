import Foundation
import Observation

enum ShortcutChange: Equatable, Sendable {
    case saved
    case conflict(ShortcutAction)
    case missingModifier
}

@MainActor
@Observable
final class ShortcutStore {
    static let storageKey = "keyboardShortcuts"
    static let shared = ShortcutStore()

    private(set) var overrides: [ShortcutAction: KeyCombination]
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        overrides = Self.load(from: defaults)
    }

    var hasOverrides: Bool { !overrides.isEmpty }

    func combination(for action: ShortcutAction) -> KeyCombination {
        overrides[action] ?? action.defaultCombination
    }

    func isCustomized(_ action: ShortcutAction) -> Bool {
        overrides[action] != nil
    }

    func conflict(for combination: KeyCombination, excluding action: ShortcutAction) -> ShortcutAction? {
        ShortcutAction.allCases.first { $0 != action && self.combination(for: $0) == combination }
    }

    @discardableResult
    func set(_ combination: KeyCombination, for action: ShortcutAction) -> ShortcutChange {
        guard combination.hasCommandModifier else { return .missingModifier }
        if let other = conflict(for: combination, excluding: action) { return .conflict(other) }
        overrides[action] = combination == action.defaultCombination ? nil : combination
        save()
        return .saved
    }

    @discardableResult
    func reset(_ action: ShortcutAction) -> ShortcutChange {
        set(action.defaultCombination, for: action)
    }

    func restoreDefaults() {
        overrides = [:]
        save()
    }

    private func save() {
        let stored = Dictionary(uniqueKeysWithValues: overrides.map { ($0.key.rawValue, $0.value) })
        if stored.isEmpty { defaults.removeObject(forKey: Self.storageKey) }
        else if let data = try? JSONEncoder().encode(stored) { defaults.set(data, forKey: Self.storageKey) }
    }

    private static func load(from defaults: UserDefaults) -> [ShortcutAction: KeyCombination] {
        guard let data = defaults.data(forKey: storageKey),
              let stored = try? JSONDecoder().decode([String: KeyCombination].self, from: data) else { return [:] }
        return Dictionary(uniqueKeysWithValues: stored.compactMap { key, value in ShortcutAction(rawValue: key).map { ($0, value) } })
    }
}
