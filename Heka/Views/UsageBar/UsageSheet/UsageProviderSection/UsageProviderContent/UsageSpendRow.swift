import SwiftUI

struct UsageSpendRow: View {
    let spend: UsageSpend

    private var amounts: String {
        let style = FloatingPointFormatStyle<Double>.Currency(code: spend.currency)
        return String(localized: "\(spend.spent.formatted(style)) of \(spend.limit.formatted(style))")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text("Extra Usage").font(.label)
                Spacer()
                Text(spend.isEnabled ? amounts : String(localized: "Disabled"))
                    .font(.callout).monospacedDigit()
                    .foregroundStyle(spend.isEnabled ? Color.textPrimary : Color.textSecondary)
            }
            if spend.isEnabled, spend.limit > 0 {
                let percent = spend.spent / spend.limit * 100
                UsageGauge(fraction: min(1, percent / 100), level: UsageLevel(usedPercent: percent))
            }
            Text("Credits billed beyond your plan limits, each month.")
                .font(.caption).foregroundStyle(Color.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }
}
