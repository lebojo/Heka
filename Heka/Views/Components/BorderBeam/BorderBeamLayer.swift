import SwiftUI

struct BorderBeamLayer: View {
    @Environment(\.self) private var environment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.borderBeamSpeed) private var speed
    @Environment(\.workspaceVisible) private var workspaceVisible
    @Environment(\.scenePhase) private var scenePhase

    @State private var isRunning = false
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

    private var isPaused: Bool {
        !isRunning || reduceMotion || !workspaceVisible || scenePhase == .background
    }

    var body: some View {
        let flatColors = flatten(colors)
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: nil, paused: isPaused)) { timeline in
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
            guard isRunning else { return }
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
