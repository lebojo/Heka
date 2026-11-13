import SwiftUI
import Textual

struct SessionTableStyle: StructuredText.TableStyle {
    func makeBody(configuration: Configuration) -> some View {
        Overflow {
            configuration.label
                .fixedSize(horizontal: true, vertical: true)
                .textual.tableOverlay { layout in
                    Canvas { context, _ in
                        for divider in layout.dividers() {
                            context.fill(Path(divider), with: .color(Palette.textTertiary))
                        }
                    }
                }
                .padding(1)
        }
        .textual.tableCellSpacing(horizontal: 1, vertical: 1)
        .textual.blockSpacing(.fontScaled(top: 0.5, bottom: 1))
    }
}
