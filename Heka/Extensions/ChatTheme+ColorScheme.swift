import SwiftUI

extension ChatTheme {
    var surface: Color { usesPureBlack ? Color.pureBlackSurface : Color.surface }

    func colorScheme(following system: ColorScheme) -> ColorScheme {
        prefersDark.map { $0 ? .dark : .light } ?? system
    }
}
