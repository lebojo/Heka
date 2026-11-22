import SwiftUI

enum BorderBeamStyle: Sendable {
    case large
    case small
    case line

    var arc: CGFloat { self == .small ? 0.5 : 0.36 }

    var glowReach: CGFloat {
        switch self {
        case .large: 20
        case .small: 4
        case .line: 10
        }
    }
}

enum BorderBeamShape: Sendable {
    case rounded(CGFloat)
    case capsule
    case circle

    var cornerRadius: CGFloat {
        switch self {
        case .rounded(let radius): radius
        case .capsule, .circle: 10_000
        }
    }
}

enum BorderBeamDirection: Sendable {
    case leftToRight
    case rightToLeft

    var shaderValue: Float { self == .leftToRight ? 1 : -1 }
}

struct BorderBeamTiming: Sendable {
    static let standard = BorderBeamTiming()

    var rotateDuration: Double = 2.4
    var lineDuration: Double = 2.0
    var fade: Double = 0.6
}

enum BorderBeamPalette {
    static func single(_ color: Color) -> [Color] {
        [color.opacity(0.3), color, color.opacity(0.3)]
    }
}

final class BorderBeamClock {
    private var last: Date?
    private(set) var phase = Double.random(in: 0..<1)

    func advance(to date: Date, rate: Double) -> Double {
        if let last {
            let elapsed = min(max(date.timeIntervalSince(last), 0), 0.1)
            phase += elapsed * rate
            phase -= floor(phase)
        }
        last = date
        return phase
    }

    func resync() {
        last = nil
    }
}
