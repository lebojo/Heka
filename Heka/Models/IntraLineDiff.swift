import Foundation

struct IntraLineDiff: Equatable, Sendable {
    static let maximumLength = 1_000
    static let refinementLength = 64

    let old: [Range<Int>]
    let new: [Range<Int>]

    init?(old oldText: String, new newText: String) {
        let oldCharacters = Array(oldText)
        let newCharacters = Array(newText)
        guard oldText != newText, oldCharacters.count <= Self.maximumLength, newCharacters.count <= Self.maximumLength else { return nil }
        let oldTokens = Self.tokens(oldCharacters)
        let newTokens = Self.tokens(newCharacters)
        let matches = Self.commonSubsequence(oldTokens.map { oldCharacters[$0] }, newTokens.map { newCharacters[$0] })
        guard matches.contains(where: { !oldCharacters[oldTokens[$0.old]].allSatisfy(\.isWhitespace) }) else { return nil }
        var oldChanges: [Range<Int>] = []
        var newChanges: [Range<Int>] = []
        var previous = (old: 0, new: 0)
        for match in matches + [(old: oldTokens.count, new: newTokens.count)] {
            let oldSpan = Self.span(oldTokens[previous.old..<match.old])
            let newSpan = Self.span(newTokens[previous.new..<match.new])
            let refined = Self.refine(oldSpan, in: oldCharacters, newSpan, in: newCharacters)
            oldChanges += refined.old
            newChanges += refined.new
            previous = (match.old + 1, match.new + 1)
        }
        old = Self.merged(oldChanges)
        new = Self.merged(newChanges)
    }

    private static func tokens(_ characters: [Character]) -> [Range<Int>] {
        var result: [Range<Int>] = []
        var start = 0
        while start < characters.count {
            var end = start + 1
            if let kind = TokenKind(characters[start]) {
                while end < characters.count, TokenKind(characters[end]) == kind { end += 1 }
            }
            result.append(start..<end)
            start = end
        }
        return result
    }

    private static func span(_ tokens: ArraySlice<Range<Int>>) -> Range<Int>? {
        guard let first = tokens.first, let last = tokens.last else { return nil }
        return first.lowerBound..<last.upperBound
    }

    private static func refine(_ oldSpan: Range<Int>?, in oldCharacters: [Character],
                               _ newSpan: Range<Int>?, in newCharacters: [Character]) -> (old: [Range<Int>], new: [Range<Int>]) {
        guard let oldSpan, let newSpan, max(oldSpan.count, newSpan.count) <= refinementLength else {
            return (oldSpan.map { [$0] } ?? [], newSpan.map { [$0] } ?? [])
        }
        let matches = commonSubsequence(Array(oldCharacters[oldSpan]), Array(newCharacters[newSpan]))
        guard matches.count * 2 >= max(oldSpan.count, newSpan.count) else { return ([oldSpan], [newSpan]) }
        let oldMatched = Set(matches.map { $0.old + oldSpan.lowerBound })
        let newMatched = Set(matches.map { $0.new + newSpan.lowerBound })
        return (oldSpan.filter { !oldMatched.contains($0) }.map { $0..<$0 + 1 },
                newSpan.filter { !newMatched.contains($0) }.map { $0..<$0 + 1 })
    }

    private static func commonSubsequence<Element: Equatable>(_ old: [Element], _ new: [Element]) -> [(old: Int, new: Int)] {
        var prefix = 0
        while prefix < old.count, prefix < new.count, old[prefix] == new[prefix] { prefix += 1 }
        var suffix = 0
        while suffix < old.count - prefix, suffix < new.count - prefix, old[old.count - 1 - suffix] == new[new.count - 1 - suffix] { suffix += 1 }
        let oldMiddle = old.count - prefix - suffix
        let newMiddle = new.count - prefix - suffix
        var lengths = Array(repeating: Array(repeating: 0, count: newMiddle + 1), count: oldMiddle + 1)
        for i in stride(from: oldMiddle - 1, through: 0, by: -1) {
            for j in stride(from: newMiddle - 1, through: 0, by: -1) {
                lengths[i][j] = old[prefix + i] == new[prefix + j] ? lengths[i + 1][j + 1] + 1 : max(lengths[i + 1][j], lengths[i][j + 1])
            }
        }
        var result = (0..<prefix).map { (old: $0, new: $0) }
        var i = 0
        var j = 0
        while i < oldMiddle, j < newMiddle {
            if old[prefix + i] == new[prefix + j] {
                result.append((prefix + i, prefix + j))
                i += 1
                j += 1
            } else if lengths[i + 1][j] >= lengths[i][j + 1] {
                i += 1
            } else {
                j += 1
            }
        }
        result += (0..<suffix).map { (old: old.count - suffix + $0, new: new.count - suffix + $0) }
        return result
    }

    private static func merged(_ ranges: [Range<Int>]) -> [Range<Int>] {
        ranges.reduce(into: []) { result, range in
            if let last = result.last, last.upperBound == range.lowerBound {
                result[result.count - 1] = last.lowerBound..<range.upperBound
            } else {
                result.append(range)
            }
        }
    }
}

private enum TokenKind {
    case word, space

    init?(_ character: Character) {
        if character.isLetter || character.isNumber || character == "_" {
            self = .word
        } else if character.isWhitespace {
            self = .space
        } else {
            return nil
        }
    }
}
