import SwiftUI

extension View {
    func borderBeam(shape: BorderBeamShape = .rounded(26), style: BorderBeamStyle = .large, direction: BorderBeamDirection = .leftToRight,
                    isActive: Bool = true, colors: [Color], intensity: Double = 1, timing: BorderBeamTiming = .standard) -> some View {
        overlay {
            BorderBeamLayer(shape: shape, style: style, direction: direction, isActive: isActive,
                            colors: colors, intensity: intensity, timing: timing)
        }
    }

    func borderBeam(isActive: Bool, cornerRadius: CGFloat, color: Color = .accentColor) -> some View {
        borderBeam(shape: .rounded(cornerRadius), isActive: isActive, colors: BorderBeamPalette.single(color))
    }
}
