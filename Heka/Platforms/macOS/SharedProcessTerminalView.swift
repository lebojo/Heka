import AppKit
import SwiftTerm

@MainActor protocol TerminalProcessReceiver: AnyObject {
    func terminalReceived(_ slice: ArraySlice<UInt8>)
    func terminalUsedLocally()
    func terminalResized()
    func terminalTitleChanged(_ title: String)
    func terminalProcessEnded(exitCode: Int32?)
}

class SharedProcessTerminalView: TerminalView, TerminalViewDelegate, @preconcurrency LocalProcessDelegate {
    private enum ColorSource: Equatable {
        case palette(TerminalPalette)
        case system(NSAppearance.Name?)
    }

    private static let pasteStart = Array("\u{1b}[200~".utf8)
    private static let pasteEnd = Array("\u{1b}[201~".utf8)

    weak var receiver: TerminalProcessReceiver?
    private(set) lazy var process = LocalProcess(delegate: self, dispatchQueue: .main)
    private var colorSource: ColorSource?
    private var cursorStyle: CursorStyle?
    private var answersHost = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        terminalDelegate = self
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        terminalDelegate = self
    }

    var usesBracketedPaste: Bool { terminalInputStateSnapshot()?.bracketedPasteMode == true }
    var usesApplicationCursor: Bool { terminalInputStateSnapshot()?.applicationCursor == true }

    func dataReceived(slice: ArraySlice<UInt8>) {
        answersHost = true
        feed(byteArray: slice)
        answersHost = false
        receiver?.terminalReceived(slice)
    }

    func processTerminated(_ source: LocalProcess, exitCode: Int32?) {
        programStatusProcessExited()
        receiver?.terminalProcessEnded(exitCode: exitCode)
    }

    func processFailedToStart(_ source: LocalProcess, error: LocalProcessError) {}

    func getWindowSize() -> winsize {
        let grid = terminalDimensions
        let scale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 1
        let pixels = getOptimalFrameSize().size
        return winsize(ws_row: UInt16(clamping: grid.rows), ws_col: UInt16(clamping: grid.cols),
                       ws_xpixel: UInt16(clamping: Int(pixels.width * scale)), ws_ypixel: UInt16(clamping: Int(pixels.height * scale)))
    }

    nonisolated override func send(source: Terminal, data: ArraySlice<UInt8>) {
        guard Thread.isMainThread, MainActor.assumeIsolated({ answersHost }) else { return super.send(source: source, data: data) }
        let reply = Array(data)
        DispatchQueue.main.async { [weak self] in
            MainActor.assumeIsolated { self?.process.send(data: reply[...]) }
        }
    }

    func send(source: TerminalView, data: ArraySlice<UInt8>) {
        process.send(data: data)
    }

    func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {
        updateProcessWindowSize()
        receiver?.terminalResized()
    }

    func setTerminalTitle(source: TerminalView, title: String) {
        receiver?.terminalTitleChanged(title)
    }

    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}

    func scrolled(source: TerminalView, position: Double) {}

    func rangeChanged(source: TerminalView, startY: Int, endY: Int) {}

    func requestOpenLink(source: TerminalView, request: TerminalLinkRequest) {
        guard let link = TerminalLink(request.link) else { return }
        NSWorkspace.shared.open(link.url)
    }

    override func paste(_ sender: Any) {
        guard usesBracketedPaste, let text = NSPasteboard.general.string(forType: .string) else { return super.paste(sender) }
        send(data: Self.pasteStart[...])
        send(txt: text.bracketedPasteSafe)
        send(data: Self.pasteEnd[...])
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        updateProcessWindowSize()
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        updateProcessWindowSize()
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

    private func updateProcessWindowSize() {
        var size = getWindowSize()
        process.updateWindowSize(&size)
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
        installColors((palette?.ansi ?? TerminalTheme.terminalAppANSI).map(\.terminalColor))
    }

    private func applyCursorStyle(_ style: CursorStyle) {
        guard style != cursorStyle else { return }
        cursorStyle = style
        setCursorStyle(style)
    }
}
