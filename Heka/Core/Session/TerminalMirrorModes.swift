import Foundation

struct TerminalMirrorModes {
    struct Margins: Equatable {
        var top = 0
        var bottom: Int?
        var left = 0
        var right: Int?
    }

    private struct Page {
        var margins = Margins()
        var savedAttributes = TerminalMirrorAttributes()
    }

    private enum State { case ground, escape, csi, osc, string }
    private var state = State.ground
    private var parameters: [UInt8] = []
    private var overflow = false
    private var utf8Remaining = 0
    private(set) var modes: [Int: Bool] = [25: true, 7: true, 1007: true]
    private(set) var mouseEncoding = 0
    private(set) var insert = false
    private(set) var newline = false
    private(set) var attributes = TerminalMirrorAttributes()
    private var page = Page()
    private var otherPage = Page()
    private var isAlternate = false
    private var columns: Int?
    private var rows: Int?
    private static let tracked: Set<Int> = [5, 6, 7, 25, 66, 69, 1004, 1007]

    var margins: Margins { page.margins }

    mutating func resize(columns: Int, rows: Int) {
        guard columns != self.columns || rows != self.rows else { return }
        if let previous = self.rows, rows > previous { page.margins.top = 0 }
        page.margins.bottom = nil
        page.margins.left = 0
        page.margins.right = nil
        otherPage.margins = Margins()
        self.columns = columns
        self.rows = rows
    }

    mutating func append(_ bytes: some Sequence<UInt8>) {
        for byte in bytes {
            if utf8Remaining > 0 {
                if (0x80...0xbf).contains(byte) { utf8Remaining -= 1; continue }
                utf8Remaining = 0
            }
            if byte >= 0xc2 {
                utf8Remaining = byte <= 0xdf ? 1 : (byte <= 0xef ? 2 : (byte <= 0xf4 ? 3 : 0))
                continue
            }
            if byte == 0x18 || byte == 0x1a || byte == 0x9c { state = .ground; continue }
            if byte == 0x1b { state = .escape; continue }
            if byte == 0x9b { state = .csi; parameters = []; overflow = false; continue }
            if byte == 0x9d || byte == 0x9f { state = .osc; continue }
            if byte == 0x90 || byte == 0x98 || byte == 0x9e { state = .string; continue }
            switch state {
            case .ground: break
            case .escape:
                switch byte {
                case 0x5b: state = .csi; parameters = []; overflow = false
                case 0x5d, 0x5f: state = .osc
                case 0x50, 0x5e, 0x58: state = .string
                case 0x3d: modes[66] = true; state = .ground
                case 0x3e: modes[66] = false; state = .ground
                case 0x37: page.savedAttributes = attributes; state = .ground
                case 0x38: attributes = page.savedAttributes; state = .ground
                case 0x63: reset()
                default: state = .ground
                }
            case .csi:
                if (0x40...0x7e).contains(byte) {
                    if !overflow { apply(final: byte) }
                    state = .ground
                } else if (0x20...0x3f).contains(byte) {
                    if parameters.count < 256 { parameters.append(byte) } else { overflow = true }
                }
            case .osc:
                if byte == 7 { state = .ground }
            case .string: break
            }
        }
    }

    private mutating func reset() {
        let size = (columns, rows)
        self = Self()
        (columns, rows) = size
    }

    private mutating func apply(final: UInt8) {
        let value = String(decoding: parameters, as: UTF8.self)
        if final == 0x70 && value == "!" {
            softReset()
            return
        }
        if value.utf8.allSatisfy({ (48...58).contains($0) || $0 == 59 }) {
            applyPlain(final: final, value)
            return
        }
        let body = value.dropFirst()
        guard final == 0x68 || final == 0x6c, value.hasPrefix("?"), body.utf8.allSatisfy({ (48...57).contains($0) || $0 == 59 }) else { return }
        for number in Self.numbers(body) {
            applyPrivate(number, enabled: final == 0x68)
        }
    }

    private mutating func softReset() {
        modes[25] = true; modes[6] = false; modes[7] = true; modes[66] = false; modes[69] = false
        insert = false; newline = false
        page = Page()
        attributes = TerminalMirrorAttributes()
    }

    private mutating func applyPlain(final: UInt8, _ value: String) {
        switch final {
        case 0x6d: attributes.apply(value)
        case 0x72: setScrollRegion(Self.numbers(value))
        case 0x73 where modes[69] == true: setLeftRightMargins(Self.numbers(value))
        case 0x73: page.savedAttributes = attributes
        case 0x75: attributes = page.savedAttributes
        case 0x68, 0x6c:
            for number in Self.numbers(value) {
                if number == 4 { insert = final == 0x68 }
                if number == 20 { newline = final == 0x68 }
            }
        default: break
        }
    }

    private mutating func applyPrivate(_ number: Int, enabled: Bool) {
        if [47, 1047, 1049].contains(number) {
            modes[25] = true
            switchBuffer(number, alternate: enabled)
        }
        if Self.tracked.contains(number) { modes[number] = enabled }
        if number == 69, !enabled { page.margins.left = 0; page.margins.right = nil }
        if [1005, 1006, 1015, 1016].contains(number) { mouseEncoding = enabled ? number : 0 }
    }

    private mutating func switchBuffer(_ number: Int, alternate: Bool) {
        if alternate, number == 1049 { page.savedAttributes = attributes }
        if alternate != isAlternate {
            swap(&page, &otherPage)
            isAlternate = alternate
            if !alternate, number != 47 { otherPage.margins = Margins() }
        }
        if !alternate, number == 1049 { attributes = page.savedAttributes }
    }

    private mutating func setScrollRegion(_ numbers: [Int]) {
        let top = max(0, (numbers.first ?? 0) - 1)
        let requested = numbers.count > 1 && numbers[1] != 0 ? numbers[1] : nil
        let last = rows.map { $0 - 1 }
        let bottom = requested.map { min($0 - 1, last ?? $0 - 1) }
        guard top < (bottom ?? last ?? .max) else { return }
        page.margins.top = top
        page.margins.bottom = bottom == last ? nil : bottom
    }

    private mutating func setLeftRightMargins(_ numbers: [Int]) {
        let limit = (columns ?? Int.max) - 1
        let right = numbers.count > 1 ? min(limit, max(0, numbers[1] - 1)) : nil
        let left = min(limit, max(0, (numbers.first ?? 1) - 1), right ?? limit)
        page.margins.left = left
        page.margins.right = right == limit ? nil : right
    }

    private static func numbers(_ value: some StringProtocol) -> [Int] {
        value.split(separator: ";", omittingEmptySubsequences: false).map { Int($0) ?? 0 }
    }
}
