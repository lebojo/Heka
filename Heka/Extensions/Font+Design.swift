import SwiftUI

extension Font {
    static let display = Font.system(size: 22, weight: .semibold)
    static let sheetTitle = Font.title3.weight(.semibold)
    static let sectionTitle = Font.subheadline.weight(.semibold)
    static let label = Font.callout.weight(.medium)
    static let captionMono = Font.system(.caption, design: .monospaced)
    static let code = Font.system(size: 12, design: .monospaced)
    static let chatOutput = Font.system(.callout, design: .monospaced)
    static let chatQuestion = Font.body.weight(.semibold)
    static let chatChoice = Font.body.weight(.medium)
    static let chatBody = Font.system(size: Dimension.Chat.bodyFontSize)
    static let chatInput = Font.body

    static let xxs = Font.system(size: 9)
    static let xs = Font.system(size: 10)
    static let s = Font.system(size: 11)
    static let m = Font.system(size: 12)
    static let l = Font.system(size: 13)
    static let xl = Font.system(size: 14)

    static let heroSymbol = Font.system(size: 42, weight: .ultraLight)
    static let emptyStateSymbol = Font.system(size: 26, weight: .light)
    static let statusDot = Font.system(size: 5)
    static let sendSymbol = Font.title
}
