import SwiftUI

extension View {
    func borderBeam(isActive: Bool, cornerRadius: CGFloat) -> some View {
        overlay {
            BorderBeam(isActive: isActive, cornerRadius: cornerRadius)
        }
    }
}

private let beamPeriod: TimeInterval = 3

private struct BorderBeam: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let isActive: Bool
    let cornerRadius: CGFloat

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius)
    }

    var body: some View {
        ZStack {
            if isActive {
                Group {
                    if reduceMotion {
                        shape.strokeBorder(Palette.accent.opacity(0.6), lineWidth: Stroke.regular)
                    } else {
                        TimelineView(.animation) { timeline in
                            beam(at: angle(at: timeline.date))
                        }
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.smooth, value: isActive)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func beam(at angle: Angle) -> some View {
        let gradient = AngularGradient(colors: [.clear, .clear, Palette.accent.opacity(0.4), Palette.accent, .clear],
                                       center: .center, angle: angle)
        return shape.strokeBorder(gradient, lineWidth: Stroke.regular)
    }

    private func angle(at date: Date) -> Angle {
        .degrees(date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: beamPeriod) / beamPeriod * 360)
    }
}
