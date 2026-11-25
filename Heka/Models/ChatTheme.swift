import Foundation

enum ChatTheme: String, CaseIterable, Identifiable, Sendable {
    static let storageKey = "chatTheme"

    case system, light, dark, oled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: String(localized: "System")
        case .light: String(localized: "Light")
        case .dark: String(localized: "Dark")
        case .oled: "OLED"
        }
    }

    var prefersDark: Bool? {
        switch self {
        case .system: nil
        case .light: false
        case .dark, .oled: true
        }
    }

    var usesPureBlack: Bool { self == .oled }
}
