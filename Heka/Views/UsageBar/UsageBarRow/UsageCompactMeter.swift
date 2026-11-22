import SwiftUI

struct UsageCompactMeter: View {
    let window: UsageWindow

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Text(window.kind.shortTitle).foregroundStyle(Color.textSecondary)
            UsageGauge(fraction: window.fraction, level: window.level)
            Text(window.percentText)
                .monospacedDigit()
                .foregroundStyle(window.level == .comfortable ? Color.textSecondary : window.level.tint)
                .frame(minWidth: Dimension.Usage.percentMinWidth, alignment: .trailing)
        }
        .font(.xs)
    }
}
