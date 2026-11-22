import Foundation
import SwiftTerm

private final class Delegate: TerminalDelegate {
    var replies = Data()
    func send(source: Terminal, data: ArraySlice<UInt8>) { replies.append(contentsOf: data) }
}

extension Terminal: TerminalContentSource {
    func terminalContentSnapshot(region: TerminalContentRegion, buffer: Terminal.BufferKind) -> TerminalContentSnapshot? {
        contentSnapshot(region: region, buffer: buffer)
    }

    func screen(_ modes: TerminalMirrorModes, previous: TerminalScreen? = nil) -> TerminalScreen {
        TerminalScreen(content: contentSnapshot(region: TerminalScreen.region(columns: cols)), cursorStyle: options.cursorStyle,
                       modes: modes, previous: previous)
    }
}

@main struct TerminalMirrorTests {
    static func require(_ condition: @autoclosure () -> Bool, _ message: String) {
        precondition(condition(), message)
    }

    static func main() {
        let hostDelegate = Delegate(), peerDelegate = Delegate()
        let host = Terminal(delegate: hostDelegate), peer = Terminal(delegate: peerDelegate)
        host.resize(cols: 48, rows: 12)
        peer.resize(cols: 48, rows: 12)
        var modes = TerminalMirrorModes()
        var previous: TerminalScreen?
        func feed(_ value: String) {
            let bytes = Data(value.utf8)
            modes.append(bytes)
            host.feed(byteArray: Array(bytes))
        }
        func sync(full: Bool = false) {
            let screen = host.screen(modes, previous: previous)
            require(screen.history == host.screen(modes).history, "Reused scrollback rows match a fresh encoding")
            let delta = screen.output(after: full ? nil : previous)
            peer.feed(byteArray: Array(delta))
            let actual = peer.screen(modes)
            require(actual.history == screen.history, "Bounded scrollback survives checkpoint and incremental scrolling")
            require(actual.lines == screen.lines, "Mirror must reproduce every cell and attribute")
            require(peer.applicationCursor == host.applicationCursor, "Application cursor mode")
            require(peer.bracketedPasteMode == host.bracketedPasteMode, "Bracketed paste mode")
            require(peer.keyboardEnhancementFlags == host.keyboardEnhancementFlags, "Kitty flags")
            require(peer.alternateScrollMode == host.alternateScrollMode, "Alternate scroll mode")
            require(peer.options.cursorStyle == host.options.cursorStyle, "Cursor style")
            require(peer.buffer.x == min(host.cols - 1, host.buffer.x) && peer.buffer.y == host.buffer.y, "Cursor position")
            let responses = String(decoding: peerDelegate.replies, as: UTF8.self)
                .replacingOccurrences(of: "\u{1b}[I", with: "").replacingOccurrences(of: "\u{1b}[O", with: "")
            require(responses.isEmpty, "Projection must not replay PTY queries")
            peerDelegate.replies = Data()
            previous = screen
        }
        feed("\u{1b}[?1049h\u{1b}[?1h\u{1b}[?2004h\u{1b}[?1007l\u{1b}[4 q\u{1b}[>3u\u{1b}[2;10r\u{1b}[38;2;12;123;234mHello 世界 👩🏽‍💻\r\nSecond line")
        sync(full: true)
        feed("\r\nThird line\u{1b}[6n\u{1b}[c")
        sync()
        require(!hostDelegate.replies.isEmpty, "The Mac answers PTY queries")
        print("PASS mirror attributes, wide characters, cursor position and style, keyboard and scroll modes, sole query responder")

        feed("\u{1b}=\u{1b}[?1004;1006;1000h\u{1b}[?25l")
        sync()
        hostDelegate.replies = Data(); peerDelegate.replies = Data()
        let queries = "\u{1b}[?66$p\u{1b}[?1004$p\u{1b}[?1006$p\u{1b}[?25$p"
        host.feed(text: queries); peer.feed(text: queries)
        require(hostDelegate.replies == peerDelegate.replies, "Keypad, focus, mouse encoding and cursor visibility match the host")
        peerDelegate.replies = Data()
        print("PASS keypad, focus reporting, mouse encoding and cursor visibility")

        feed(String(repeating: "long running output\r\n", count: 20000))
        feed("\u{1b}[2J\u{1b}[5;3H\u{1b}[1;3;4:3;58;5;123mCHECKPOINT")
        feed("\u{1b}[38;2;")
        sync(full: true)
        feed("222;11;22m✓")
        sync()
        let bytes = host.screen(modes).output(after: nil)
        require(bytes.count < 10000, "Reconnect cost is bounded by screen size, not process lifetime")
        print("PASS full checkpoint after >256 KiB, including split escape sequence")

        feed("\u{1b}[?1049l\u{1b}[r\u{1b}[0m")
        feed(String(repeating: "scrollback\r\n", count: 100))
        feed("LIVE")
        host.buffer.yDisp = 0
        sync(full: true)
        require(previous!.lines.joined().contains("LIVE"), "Mirror follows live screen even when Mac scrolls up")
        let sentHistoryEnd = previous!.historyStart + previous!.history.count
        feed(String(repeating: "more scrollback\r\n", count: 250))
        sync()
        let skipped = previous!.historyStart - sentHistoryEnd
        let kept = peer.recentText(limit: .max).split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        require(skipped > 0 && kept.contains("scrollback") && kept.contains("… " + String(localized: "\(skipped) lines not sent")),
                "A large burst keeps earlier scrollback and marks the skipped lines")
        host.resize(cols: 60, rows: 15)
        peer.resize(cols: 60, rows: 15)
        sync()
        feed("\u{1b}[3J\u{1b}[H\u{1b}[2J")
        feed(String(repeating: "after clear\r\n", count: 40))
        sync()
        print("PASS alternate-screen exit, independent scroll position and host resize")

        let wide = Terminal(delegate: Delegate()), widePeer = Terminal(delegate: Delegate())
        wide.resize(cols: 300, rows: 120)
        widePeer.resize(cols: 300, rows: 120)
        let styles = ["\u{1b}[0;1;3;4:3;38;2;200;201;202;48;2;203;204;205;9;58;5;206m", "\u{1b}[0;1;3;4:3;38;2;210;211;212;48;2;213;214;215;9m"]
        var colorful = ""
        for row in 0..<180 {
            for column in 0..<300 { colorful += styles[(row + column) % 2] + "#" }
            if row < 179 { colorful += "\r\n" }
        }
        wide.feed(text: colorful)
        let checkpoint = wide.screen(TerminalMirrorModes()).output(after: nil)
        require(checkpoint.count <= TerminalScreen.outputLimit, "A checkpoint stays within the frame budget")
        widePeer.feed(byteArray: Array(checkpoint))
        let mirrored = widePeer.screen(TerminalMirrorModes())
        require(mirrored.history.isEmpty, "The oversized checkpoint drops its scrollback")
        require(mirrored.lines == wide.screen(TerminalMirrorModes()).lines, "Dropping scrollback keeps the live screen exact")
        let huge = Terminal(delegate: Delegate()), hugePeer = Terminal(delegate: Delegate())
        huge.resize(cols: 520, rows: 160)
        hugePeer.resize(cols: 520, rows: 160)
        var frame = "\u{1b}[?1049h"
        for row in 0..<160 {
            for column in 0..<520 {
                frame += styles[(row + column) % 2] + "\(row % 10)"
            }
            if row < 159 { frame += "\r\n" }
        }
        huge.feed(text: frame)
        let alternate = huge.screen(TerminalMirrorModes()).output(after: nil)
        require(alternate.count <= TerminalScreen.outputLimit, "A styled alternate screen without scrollback stays within the frame budget")
        hugePeer.feed(byteArray: Array(alternate))
        let plain = { (terminal: Terminal) in (0..<160).map { terminal.getLine(row: $0)?.translateToString(trimRight: true) ?? "" } }
        require(plain(hugePeer) == plain(huge), "The unstyled fallback keeps the screen text exact")
        print("PASS oversized checkpoint keeps the live screen within the frame budget")

        var scanner = TerminalMirrorModes()
        for fragment in ["\u{1b}]0;fake \u{1b}[?66h", "\u{1b}\\", "\u{1b}[?", "66;1006h", "\u{1b}[?25l"] {
            scanner.append(Data(fragment.utf8))
        }
        require(scanner.modes[66] == true && scanner.mouseEncoding == 1006 && scanner.modes[25] == false, "Fragmented mode controls")
        scanner.append(Data("\u{1b}]0;[?66l\u{7}".utf8))
        require(scanner.modes[66] == true, "OSC payload cannot change input modes")
        scanner.append(Data("\u{1b}[!p".utf8))
        require(scanner.modes[66] == false && scanner.modes[25] == true && scanner.mouseEncoding == 1006, "DECSTR semantics")
        scanner.append(Data("\u{1b}[?1007l".utf8))
        require(scanner.modes[1007] == false, "Alternate scroll mode")
        scanner.append(Data("\u{1b}c".utf8))
        require(scanner.mouseEncoding == 0 && scanner.modes[66] != true && scanner.modes[1007] == true, "RIS semantics")
        print("PASS bounded streaming input-mode scanner")

        let reader = Terminal(delegate: Delegate())
        reader.resize(cols: 10, rows: 4)
        reader.feed(text: (1...400).map { "line \($0)" }.joined(separator: "\r\n") + "\r\nabcdefghij klmno\r\nlast")
        require(reader.recentLines(2) == "abcdefghij klmno\nlast", "Recent lines join soft-wrapped rows: \(reader.recentLines(2))")
        require(reader.recentLines(1000).hasPrefix("line 1\n") && reader.recentLines(1000).hasSuffix("line 400\nabcdefghij klmno\nlast"),
                "Recent lines reach the scrollback")
        require(reader.recentText(limit: 12) == " klmno\nlast",
                "Recent text stops at its limit: \(reader.recentText(limit: 12))")
        print("PASS screen reads for heka terminal read and the chat transcript")
    }
}
