/*
Border beam ported from https://github.com/ismnoiet/border-beam-ios

MIT License

Copyright (c) 2026 ismnoiet

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/
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

extension EnvironmentValues {
    @Entry var borderBeamSpeed: Double = 1
}
