import Foundation

struct HexColor: Hashable, Sendable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = Self.clamped(red)
        self.green = Self.clamped(green)
        self.blue = Self.clamped(blue)
        self.alpha = Self.clamped(alpha)
    }

    init?(hex: String) {
        var digits = hex.trimmingCharacters(in: .whitespaces)
        if digits.hasPrefix("#") { digits.removeFirst() }
        guard digits.count == 6 || digits.count == 8, let value = UInt32(digits, radix: 16) else { return nil }
        let rgba = digits.count == 6 ? value << 8 | 0xFF : value
        self.init(red: Self.component(rgba, shift: 24), green: Self.component(rgba, shift: 16),
                  blue: Self.component(rgba, shift: 8), alpha: Self.component(rgba, shift: 0))
    }

    var hex: String {
        let rgba = [red, green, blue, alpha].map { Int(($0 * 255).rounded()) }
        return "#" + rgba.map { String(format: "%02X", $0) }.joined()
    }

    private static func component(_ value: UInt32, shift: UInt32) -> Double {
        Double((value >> shift) & 0xFF) / 255
    }

    private static func clamped(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
