import SwiftUI

struct SidebarAppearancePicker: View {
    @Binding var appearance: SidebarAppearance

    #if os(macOS)
    private let columns = Array(repeating: GridItem(.fixed(IconSize.xl), spacing: Spacing.s), count: 11)
    #else
    private let columns = [GridItem(.adaptive(minimum: IconSize.xl), spacing: Spacing.s)]
    #endif

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            VStack(alignment: .leading, spacing: Spacing.m) {
                Text("Icon").font(Typography.label)
                LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.s) {
                    ForEach(SidebarSymbol.allCases) { symbol in
                        Button { appearance.symbol = symbol } label: {
                            SymbolCell(symbol: symbol, color: appearance.color, isSelected: appearance.displaySymbol == symbol)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(appearance.displaySymbol == symbol ? .isSelected : [])
                    }
                }
            }
            VStack(alignment: .leading, spacing: Spacing.m) {
                Text("Color").font(Typography.label)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: IconSize.m + Spacing.xxs * 2), spacing: Spacing.xs)], alignment: .leading, spacing: Spacing.xs) {
                    Button { appearance.tint = nil } label: {
                        TintSwatch(color: appearance.kind.defaultColor, isAutomatic: true, isSelected: appearance.tint == nil)
                    }
                    .buttonStyle(.plain)
                    .help("Automatic")
                    .accessibilityLabel("Automatic")
                    .accessibilityAddTraits(appearance.tint == nil ? .isSelected : [])
                    ForEach(SidebarTint.allCases) { tint in
                        Button { appearance.tint = tint } label: {
                            TintSwatch(color: tint.color, isAutomatic: false, isSelected: appearance.tint == tint)
                        }
                        .buttonStyle(.plain)
                        .help(tint.title)
                        .accessibilityLabel(tint.title)
                        .accessibilityAddTraits(appearance.tint == tint ? .isSelected : [])
                    }
                }
            }
        }
    }
}
