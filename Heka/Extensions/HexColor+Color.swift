import SwiftUI

extension HexColor {
    init(_ color: Color, in environment: EnvironmentValues) {
        let resolved = color.resolve(in: environment)
        self.init(red: Double(resolved.red), green: Double(resolved.green), blue: Double(resolved.blue), alpha: Double(resolved.opacity))
    }

    var color: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha) }
}

extension BorderBeamAppearance {
    private func beamColor(for agent: ConversationAgent?) -> Color {
        agent.map { color(for: $0).color } ?? Color.accentColor
    }

    func beamColors(for agent: ConversationAgent?) -> [Color] {
        switch colorMode {
        case .perAgent: BorderBeamPalette.single(beamColor(for: agent))
        case .multicolor: multicolorPalette.map(\.color)
        }
    }

    subscript(colorOf agent: ConversationAgent) -> Color {
        get { color(for: agent).color }
        set { setColor(HexColor(newValue, in: EnvironmentValues()), for: agent) }
    }
}
