import Foundation
import SwiftTerm

protocol TerminalContentSource {
    func terminalContentSnapshot(region: TerminalContentRegion, buffer: Terminal.BufferKind) -> TerminalContentSnapshot?
}

extension TerminalView: TerminalContentSource {}

extension TerminalContentSource {
    private var recentRowsBatch: Int { 256 }

    func recentText(limit: Int) -> String {
        var lines: [String] = []
        var size = 0
        forEachRecentRow { row in
            guard size < limit else { return false }
            lines.append(row.text)
            size += row.text.utf8.count + 1
            return true
        }
        return lines.reversed().joined(separator: "\n")
    }

    func recentLines(_ count: Int) -> String {
        var lines: [String] = []
        var continuation = ""
        forEachRecentRow { row in
            guard lines.count < count else { return false }
            let segment = (continuation.isEmpty ? row.text : row.untrimmedText) + continuation
            if row.isWrapped {
                continuation = segment
                return true
            }
            continuation = ""
            if !lines.isEmpty || !segment.isEmpty { lines.append(segment) }
            return true
        }
        if !continuation.isEmpty, lines.count < count { lines.append(continuation) }
        return lines.reversed().joined(separator: "\n")
    }

    private func forEachRecentRow(_ visit: (TerminalContentRowSnapshot) -> Bool) {
        var region = TerminalContentRegion.history(maximumScrollbackRows: recentRowsBatch)
        while let snapshot = terminalContentSnapshot(region: region, buffer: .active), !snapshot.rows.isEmpty {
            for row in snapshot.rows.reversed() {
                guard visit(row) else { return }
            }
            let start = snapshot.capturedRange.lowerBound
            region = .rows(max(0, start - recentRowsBatch)..<start)
        }
    }
}

private extension TerminalContentRowSnapshot {
    var untrimmedText: String {
        cells.filter { $0.width > 0 }.map { $0.isBlank ? " " : $0.text }.joined()
    }
}
