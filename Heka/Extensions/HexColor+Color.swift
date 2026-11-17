import SwiftUI

extension HexColor {
    init(_ color: Color, in environment: EnvironmentValues) {
        let resolved = color.resolve(in: environment)
        self.init(red: Double(resolved.red), green: Double(resolved.green), blue: Double(resolved.blue), alpha: Double(resolved.opacity))
    }

    var color: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha) }
}

extension BorderBeamAppearance {
    func beamColor(for agent: ConversationAgent?) -> Color {
        agent.map { color(for: $0).color } ?? Palette.accent
    }
}
