import Foundation

struct SlashCommandMatch: Hashable, Sendable, Identifiable {
    let command: SlashCommand
    let matchedOffsets: [Int]
    let score: Int

    var id: String { command.id }
}

enum SlashCommandMatcher {
    static func query(in draft: String) -> String? {
        guard draft.hasPrefix("/") else { return nil }
        let query = draft.dropFirst()
        guard !query.contains(where: \.isWhitespace) else { return nil }
        return String(query)
    }

    static func matches(for query: String, in commands: [SlashCommand], recent: [String]) -> [SlashCommandMatch] {
        commands.enumerated()
            .compactMap { index, command in match(query, command, recency: recencyBonus(command.name, recent)).map { ($0, index) } }
            .sorted { $0.0.score != $1.0.score ? $0.0.score > $1.0.score : $0.1 < $1.1 }
            .map(\.0)
    }

    static func commandToAcceptOnReturn(draft: String, matches: [SlashCommandMatch], selection: Int, isNavigated: Bool) -> SlashCommand? {
        guard matches.indices.contains(selection), isNavigated || matches.count == 1 else { return nil }
        let command = matches[selection].command
        return command.text == draft ? nil : command
    }

    static func insertion(for command: SlashCommand) -> String { command.text + " " }

    static func remembering(_ command: SlashCommand, in recent: [String]) -> [String] {
        Array(([command.name] + recent.filter { $0 != command.name }).prefix(8))
    }

    private static func match(_ query: String, _ command: SlashCommand, recency: Int) -> SlashCommandMatch? {
        let name = command.name.lowercased()
        guard let offsets = subsequenceOffsets(of: query.lowercased(), in: name) else { return nil }
        return SlashCommandMatch(command: command, matchedOffsets: offsets, score: score(offsets, length: name.count) + recency)
    }

    private static func subsequenceOffsets(of query: String, in name: String) -> [Int]? {
        var offsets: [Int] = []
        var remaining = query.makeIterator()
        var wanted = remaining.next()
        for (offset, character) in name.enumerated() where character == wanted {
            offsets.append(offset)
            wanted = remaining.next()
        }
        return wanted == nil ? offsets : nil
    }

    private static func score(_ offsets: [Int], length: Int) -> Int {
        guard let first = offsets.first, let last = offsets.last else { return 0 }
        let isContiguous = last - first == offsets.count - 1
        let tier = switch (isContiguous, first) {
        case (true, 0) where offsets.count == length: 400
        case (true, 0): 300
        case (true, _): 200
        default: 100
        }
        return tier - (last - first - offsets.count + 1) - first
    }

    private static func recencyBonus(_ name: String, _ recent: [String]) -> Int {
        recent.firstIndex(of: name).map { 50 - $0 * 5 } ?? 0
    }
}
