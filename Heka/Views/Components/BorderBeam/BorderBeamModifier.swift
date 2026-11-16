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

struct BorderBeamLayer: View {
    @Environment(\.self) private var environment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.borderBeamSpeed) private var speed

    @State private var isRunning = true
    @State private var clock = BorderBeamClock()

    let shape: BorderBeamShape
    let style: BorderBeamStyle
    let direction: BorderBeamDirection
    let isActive: Bool
    let colors: [Color]
    let intensity: Double
    let timing: BorderBeamTiming

    private var isLine: Bool { style == .line }

    private var duration: Double { isLine ? timing.lineDuration : timing.rotateDuration }

    var body: some View {
        let flatColors = flatten(colors)
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: nil, paused: !isRunning || reduceMotion)) { timeline in
                Rectangle()
                    .fill(Color.white)
                    .colorEffect(shader(size: geometry.size, phase: phase(at: timeline.date), colors: flatColors))
            }
        }
        .opacity(isActive ? 1 : 0)
        .animation(.easeInOut(duration: timing.fade), value: isActive)
        .task(id: isActive, updateRunning)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func shader(size: CGSize, phase: Double, colors: [Float]) -> Shader {
        ShaderLibrary.default.borderBeam(
            .float2(size),
            .float(shape.cornerRadius),
            .float(phase),
            .float(CGFloat(direction.shaderValue)),
            .float(isLine ? 1 : 0),
            .float(2),
            .float(style.arc),
            .float(style.glowReach),
            .float(intensity),
            .floatArray(colors)
        )
    }

    private func updateRunning() async {
        if isActive {
            clock.resync()
            isRunning = true
        } else {
            try? await Task.sleep(for: .seconds(timing.fade + 0.05))
            if !Task.isCancelled { isRunning = false }
        }
    }

    private func phase(at date: Date) -> Double {
        if reduceMotion { return 0.15 }
        return clock.advance(to: date, rate: max(speed, 0) / max(duration, 0.01))
    }

    private func flatten(_ colors: [Color]) -> [Float] {
        let source = colors.isEmpty ? [Color.white] : Array(colors.prefix(16))
        return source.flatMap { color -> [Float] in
            let resolved = color.resolve(in: environment)
            return [resolved.red, resolved.green, resolved.blue, resolved.opacity]
        }
    }
}

extension View {
    func borderBeam(shape: BorderBeamShape = .rounded(26), style: BorderBeamStyle = .large, direction: BorderBeamDirection = .leftToRight,
                    isActive: Bool = true, colors: [Color], intensity: Double = 1, timing: BorderBeamTiming = .standard) -> some View {
        overlay {
            BorderBeamLayer(shape: shape, style: style, direction: direction, isActive: isActive,
                            colors: colors, intensity: intensity, timing: timing)
        }
    }

    func borderBeam(isActive: Bool, cornerRadius: CGFloat, color: Color = Palette.accent) -> some View {
        borderBeam(shape: .rounded(cornerRadius), isActive: isActive, colors: BorderBeamPalette.single(color))
    }
}
