import Foundation

enum ShortcutTests {
    @MainActor static func run() throws {
        let defaultCombinations = ShortcutAction.allCases.map(\.defaultCombination)
        try CoreTests.require(Set(defaultCombinations).count == defaultCombinations.count, "Default shortcuts never conflict")
        try CoreTests.require(ShortcutArea.allCases.flatMap(\.actions).count == ShortcutAction.allCases.count, "Every shortcut belongs to one area")
        try CoreTests.require(KeyCombination("d", modifiers: [.command, .shift]).symbols == "⇧⌘D"
                                && KeyCombination(.named(.returnKey)).symbols == "⌘↩"
                                && KeyCombination("k", modifiers: [.command, .control, .option]).symbols == "⌃⌥⌘K",
                              "Shortcut symbols follow the macOS modifier order")

        try CoreTests.require(ShortcutAction.tabSelections.map(\.defaultCombination) == (1...9).map { KeyCombination(Character(String($0))) }
                                && ShortcutAction.tabSelections.allSatisfy { $0.area == .terminal },
                              "Tab selection shortcuts default to ⌘1…⌘9 in the Terminal area")

        let suite = "Heka.ShortcutTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = ShortcutStore(defaults: defaults)
        try CoreTests.require(store.combination(for: .splitRight) == KeyCombination("d") && !store.hasOverrides, "Shortcuts start at their defaults")

        let custom = KeyCombination("e", modifiers: [.command, .option])
        try CoreTests.require(store.set(custom, for: .splitRight) == .saved && store.isCustomized(.splitRight), "A free combination is saved")
        try CoreTests.require(store.set(KeyCombination("t"), for: .splitRight) == .conflict(.newTerminal)
                                && store.combination(for: .splitRight) == custom, "A conflicting combination is refused")
        try CoreTests.require(store.set(custom, for: .splitDown) == .conflict(.splitRight), "A customized combination is also taken")
        try CoreTests.require(store.set(KeyCombination("e", modifiers: [.shift]), for: .splitRight) == .missingModifier, "A shortcut needs a command modifier")
        try CoreTests.require(store.set(KeyCombination("d"), for: .splitDown) == .saved, "A freed default can be reused")
        try CoreTests.require(store.reset(.splitRight) == .conflict(.splitDown) && store.combination(for: .splitRight) == custom,
                              "Reset refuses a default now taken by another shortcut")

        let reloaded = ShortcutStore(defaults: defaults)
        try CoreTests.require(reloaded.combination(for: .splitRight) == custom && reloaded.combination(for: .splitDown) == KeyCombination("d"),
                              "Shortcuts persist in user defaults")
        try CoreTests.require(reloaded.set(KeyCombination("d", modifiers: [.command, .shift]), for: .splitDown) == .saved && !reloaded.isCustomized(.splitDown),
                              "Choosing the default again clears the override")

        reloaded.restoreDefaults()
        try CoreTests.require(!reloaded.hasOverrides && defaults.data(forKey: ShortcutStore.storageKey) == nil
                                && ShortcutStore(defaults: defaults).combination(for: .splitRight) == KeyCombination("d"),
                              "Restore Defaults clears every override")

        defaults.set(Data("{\"unknown\":\"x\",\"nextTab\":\"bad key\"}".utf8), forKey: ShortcutStore.storageKey)
        try CoreTests.require(!ShortcutStore(defaults: defaults).hasOverrides, "Unreadable stored shortcuts fall back to defaults")
        let valid = String(decoding: try JSONEncoder().encode(custom), as: UTF8.self)
        defaults.set(Data("{\"splitRight\":\(valid),\"nextTab\":\"bad key\",\"unknown\":\(valid)}".utf8), forKey: ShortcutStore.storageKey)
        let tolerant = ShortcutStore(defaults: defaults)
        try CoreTests.require(tolerant.combination(for: .splitRight) == custom && !tolerant.isCustomized(.nextTab),
                              "One unreadable shortcut keeps the other custom shortcuts")
        print("PASS keyboard shortcuts")
    }
}
