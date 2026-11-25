import Foundation

enum BorderBeamColorMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case perAgent
    case multicolor

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .perAgent: "Per Agent"
        case .multicolor: "Multicolor"
        }
    }
}

struct BorderBeamAppearance: Hashable, Sendable {
    static let storageKey = "borderBeamAppearance"

    var isEnabled = true
    var colors: [String: String] = [:]
    var colorMode = BorderBeamColorMode.perAgent

    static func defaultColor(for agent: ConversationAgent) -> HexColor {
        switch agent {
        case .claude: HexColor(red: 0.85, green: 0.47, blue: 0.34)
        case .codex: HexColor(red: 0.20, green: 0.78, blue: 0.45)
        case .openCode: HexColor(red: 1, green: 1, blue: 1)
        case .copilot: HexColor(red: 0.62, green: 0.38, blue: 0.95)
        }
    }

    var hasCustomColors: Bool { !colors.isEmpty }

    var multicolorPalette: [HexColor] { ConversationAgent.allCases.map(color(for:)) }

    func color(for agent: ConversationAgent) -> HexColor {
        colors[agent.rawValue].flatMap(HexColor.init(hex:)) ?? Self.defaultColor(for: agent)
    }

    mutating func setColor(_ color: HexColor, for agent: ConversationAgent) {
        colors[agent.rawValue] = color == Self.defaultColor(for: agent) ? nil : color.hex
    }

    mutating func resetColors() {
        colors = [:]
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.isEnabled == rhs.isEnabled && lhs.colors == rhs.colors && lhs.colorMode == rhs.colorMode
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(isEnabled)
        hasher.combine(colors)
        hasher.combine(colorMode)
    }
}

extension BorderBeamAppearance: RawRepresentable {
    init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(Stored.self, from: data) else { return nil }
        self.init(isEnabled: decoded.isEnabled, colors: decoded.colors, colorMode: decoded.colorMode ?? .perAgent)
    }

    var rawValue: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = (try? encoder.encode(Stored(isEnabled: isEnabled, colors: colors, colorMode: colorMode))) ?? Data()
        return String(decoding: data, as: UTF8.self)
    }

    private struct Stored: Codable {
        var isEnabled: Bool
        var colors: [String: String]
        var colorMode: BorderBeamColorMode?
    }
}
