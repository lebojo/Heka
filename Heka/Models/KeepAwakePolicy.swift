import Foundation

enum KeepAwakePolicy: String, Codable, CaseIterable, Identifiable {
    case never
    case fifteenMinutes
    case thirtyMinutes
    case oneHour
    case twoHours
    case always

    static let standard = Self.oneHour

    var id: Self { self }

    var idleLimit: Duration? {
        switch self {
        case .fifteenMinutes: .seconds(15 * 60)
        case .thirtyMinutes: .seconds(30 * 60)
        case .oneHour: .seconds(60 * 60)
        case .twoHours: .seconds(2 * 60 * 60)
        case .never, .always: nil
        }
    }

    var title: String {
        switch self {
        case .never: String(localized: "Never")
        case .fifteenMinutes: String(localized: "For 15 minutes after the last activity")
        case .thirtyMinutes: String(localized: "For 30 minutes after the last activity")
        case .oneHour: String(localized: "For 1 hour after the last activity")
        case .twoHours: String(localized: "For 2 hours after the last activity")
        case .always: String(localized: "Always while connected")
        }
    }
}
