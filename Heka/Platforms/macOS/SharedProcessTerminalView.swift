import AppKit
import SwiftTerm

@MainActor protocol TerminalOutputReceiver: AnyObject {
    func terminalReceived(_ slice: ArraySlice<UInt8>)
    func terminalUsedLocally()
}

class SharedProcessTerminalView: LocalProcessTerminalView {
    private enum ColorSource: Equatable {
        case palette(TerminalPalette)
        case system(NSAppearance.Name?)
    }

    private static let pasteStart = Array("\u{1b}[200~".utf8)
    private static let pasteEnd = Array("\u{1b}[201~".utf8)

    weak var outputReceiver: TerminalOutputReceiver?
    private var colorSource: ColorSource?
    private var ansiColors = TerminalTheme.terminalAppANSI.map(\.terminalColor)
    private var cursorStyle: CursorStyle?

    override init(frame: CGRect) {
        super.init(frame: frame)
        installEscapeHandlers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        installEscapeHandlers()
    }

    override func dataReceived(slice: ArraySlice<UInt8>) {
        super.dataReceived(slice: slice)
        outputReceiver?.terminalReceived(slice)
    }

    override func paste(_ sender: Any) {
        guard getTerminal().bracketedPasteMode, let text = NSPasteboard.general.string(forType: .string) else { return super.paste(sender) }
        send(data: Self.pasteStart[...])
        send(txt: text.bracketedPasteSafe)
        send(data: Self.pasteEnd[...])
    }

    override func requestOpenLink(source: TerminalView, link: String, params: [String: String]) {
        guard let link = TerminalLink(link) else { return }
        NSWorkspace.shared.open(link.url)
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        guard case .system = colorSource else { return }
        applyColors(nil)
    }

    @discardableResult func apply(_ appearance: TerminalAppearance) -> Bool {
        let resized = applyFont(appearance.nsFont)
        applyColors(appearance.palette)
        applyCursorStyle(appearance.cursorStyle)
        return resized
    }

    private func applyFont(_ newFont: NSFont) -> Bool {
        guard font.fontName != newFont.fontName || font.pointSize != newFont.pointSize else { return false }
        font = newFont
        return true
    }

    private func applyColors(_ palette: TerminalPalette?) {
        let source = palette.map(ColorSource.palette) ?? .system(effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]))
        guard source != colorSource else { return }
        colorSource = source
        if let palette {
            nativeBackgroundColor = palette.background.nsColor
            nativeForegroundColor = palette.foreground.nsColor
            caretColor = palette.cursor.nsColor
            selectedTextBackgroundColor = palette.selection.nsColor
        } else {
            effectiveAppearance.performAsCurrentDrawingAppearance {
                nativeBackgroundColor = .textBackgroundColor
                nativeForegroundColor = .textColor
                caretColor = .selectedControlColor
                selectedTextBackgroundColor = .selectedTextBackgroundColor
            }
        }
        ansiColors = (palette?.ansi ?? TerminalTheme.terminalAppANSI).map(\.terminalColor)
        installColors(ansiColors)
    }

    private func applyCursorStyle(_ style: CursorStyle) {
        guard style != cursorStyle else { return }
        cursorStyle = style
        getTerminal().setCursorStyle(style)
    }

    private func installEscapeHandlers() {
        let terminal = getTerminal()
        terminal.registerOscHandler(code: 52) { _ in }
        terminal.registerOscHandler(code: 104) { [weak self] data in self?.resetColors(data) }
    }

    private func resetColors(_ data: ArraySlice<UInt8>) {
        let indices = String(decoding: data, as: UTF8.self).split(separator: ";").compactMap { Int($0) }
        guard data.isEmpty || indices.contains(where: (0...255).contains) else { return }
        installColors(ansiColors)
    }
}
