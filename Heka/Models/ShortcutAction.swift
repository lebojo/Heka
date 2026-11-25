import Foundation

enum ShortcutArea: String, CaseIterable, Identifiable, Sendable {
    case app
    case terminal
    case chat
    case inspector

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .app: "App"
        case .terminal: "Terminal"
        case .chat: "Chat"
        case .inspector: "Inspector"
        }
    }

    var actions: [ShortcutAction] {
        ShortcutAction.allCases.filter { $0.area == self }
    }
}

enum ShortcutAction: String, CaseIterable, Identifiable, Sendable {
    case addProject
    case importFolder
    case newVirtualFolder
    case floatingTerminal
    case newTerminal
    case splitRight
    case splitDown
    case previousTab
    case nextTab
    case selectTab1
    case selectTab2
    case selectTab3
    case selectTab4
    case selectTab5
    case selectTab6
    case selectTab7
    case selectTab8
    case selectTab9
    case sendMessage
    case refreshInspector

    static let tabSelections: [ShortcutAction] = [
        .selectTab1, .selectTab2, .selectTab3, .selectTab4, .selectTab5, .selectTab6, .selectTab7, .selectTab8, .selectTab9,
    ]

    var id: Self { self }

    var area: ShortcutArea {
        switch self {
        case .addProject, .importFolder, .newVirtualFolder, .floatingTerminal: .app
        case .newTerminal, .splitRight, .splitDown, .previousTab, .nextTab,
             .selectTab1, .selectTab2, .selectTab3, .selectTab4, .selectTab5, .selectTab6, .selectTab7, .selectTab8, .selectTab9: .terminal
        case .sendMessage: .chat
        case .refreshInspector: .inspector
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .addProject: "Add Project…"
        case .importFolder: "Import Folder…"
        case .newVirtualFolder: "New Virtual Folder…"
        case .floatingTerminal: "Floating Terminal"
        case .newTerminal: "New Terminal"
        case .splitRight: "Split Right"
        case .splitDown: "Split Down"
        case .previousTab: "Previous Tab"
        case .nextTab: "Next Tab"
        case .selectTab1, .selectTab2, .selectTab3, .selectTab4, .selectTab5, .selectTab6, .selectTab7, .selectTab8, .selectTab9:
            "Select Tab \(tabNumber)"
        case .sendMessage: "Send to Session"
        case .refreshInspector: "Refresh"
        }
    }

    var defaultCombination: KeyCombination {
        switch self {
        case .addProject: KeyCombination("o")
        case .importFolder: KeyCombination("o", modifiers: [.command, .shift])
        case .newVirtualFolder: KeyCombination("n", modifiers: [.command, .shift])
        case .floatingTerminal: KeyCombination("t", modifiers: [.command, .shift])
        case .newTerminal: KeyCombination("t")
        case .splitRight: KeyCombination("d")
        case .splitDown: KeyCombination("d", modifiers: [.command, .shift])
        case .previousTab: KeyCombination("[", modifiers: [.command, .shift])
        case .nextTab: KeyCombination("]", modifiers: [.command, .shift])
        case .selectTab1, .selectTab2, .selectTab3, .selectTab4, .selectTab5, .selectTab6, .selectTab7, .selectTab8, .selectTab9:
            KeyCombination(Character(String(tabNumber)))
        case .sendMessage: KeyCombination(.named(.returnKey))
        case .refreshInspector: KeyCombination("r")
        }
    }

    private var tabNumber: Int {
        (Self.tabSelections.firstIndex(of: self) ?? 0) + 1
    }
}
