import Foundation

enum GitConfiguration {
    static let hardened = ["core.fsmonitor": "false"]
    static let listingArguments = ["config", "--list", "--show-scope", "--show-origin", "-z"]
    private static let trustedScopes: Set<String> = ["system", "global", "command"]
    private static let filterPrefix = Array("filter.".utf8)
    private static let filterCommands = ["clean", "smudge", "process"]

    static func appending(_ configuration: [String: String], to base: [String: String]) -> [String: String] {
        var environment = base
        var count = max(0, environment["GIT_CONFIG_COUNT"].flatMap(Int.init) ?? 0)
        for (key, value) in configuration.sorted(by: { $0.key < $1.key }) {
            environment["GIT_CONFIG_KEY_\(count)"] = key
            environment["GIT_CONFIG_VALUE_\(count)"] = value
            count += 1
        }
        environment["GIT_CONFIG_COUNT"] = String(count)
        return environment
    }

    struct Entry: Sendable {
        let scope: String
        let origin: String
        let keyBytes: [UInt8]
        let value: String?

        var key: String { String(decoding: keyBytes, as: UTF8.self) }
    }

    struct UnreadableFilterError: LocalizedError {
        var errorDescription: String? {
            String(localized: "A filter in this repository’s Git configuration has a name Heka can’t handle safely, so Heka doesn’t run Git here.")
        }
    }

    static func entries(in listing: Data) -> [Entry] {
        let fields = Array(listing).split(separator: 0, omittingEmptySubsequences: false)
        return stride(from: 0, to: fields.count - 2, by: 3).map { index in
            let pair = fields[index + 2].split(separator: UInt8(ascii: "\n"), maxSplits: 1, omittingEmptySubsequences: false)
            return Entry(scope: text(fields[index]), origin: text(fields[index + 1]), keyBytes: Array(pair[0]),
                         value: pair.count > 1 ? text(pair[1]) : nil)
        }
    }

    private static func text(_ bytes: ArraySlice<UInt8>) -> String {
        String(decoding: bytes, as: UTF8.self)
    }

    static func isTrue(_ value: String?) -> Bool {
        guard let value = value?.lowercased() else { return true }
        return ["true", "yes", "on"].contains(value) || (Int(value).map { $0 != 0 } ?? false)
    }

    static func untrustedFilterDrivers(in entries: [Entry]) throws -> Set<String> {
        let names = Set(entries.filter { !trustedScopes.contains($0.scope) }.compactMap { filterDriver(in: $0.keyBytes) })
        let drivers = Set(names.compactMap { String(validating: $0, as: UTF8.self) })
        guard drivers.count == names.count else { throw UnreadableFilterError() }
        return drivers
    }

    private static func filterDriver(in key: [UInt8]) -> [UInt8]? {
        guard key.starts(with: filterPrefix), let separator = key.lastIndex(of: UInt8(ascii: ".")),
              separator >= filterPrefix.count else { return nil }
        return Array(key[filterPrefix.count..<separator])
    }

    static func files(in entries: [Entry], root: String) -> Set<String> {
        var files: Set<String> = []
        for entry in entries where entry.origin.hasPrefix("file:") {
            let origin = absolute(String(entry.origin.dropFirst(5)), relativeTo: root)
            files.insert(origin)
            let isInclude = entry.key == "include.path" || (entry.key.hasPrefix("includeif.") && entry.key.hasSuffix(".path"))
            if isInclude, let value = entry.value, !value.isEmpty {
                files.insert(absolute(String(value), relativeTo: (origin as NSString).deletingLastPathComponent))
            }
        }
        return files
    }

    private static func absolute(_ path: String, relativeTo directory: String) -> String {
        let expanded = (path as NSString).expandingTildeInPath
        let full = (expanded as NSString).isAbsolutePath ? expanded : (directory as NSString).appendingPathComponent(expanded)
        return (full as NSString).standardizingPath
    }

    static func disabling(filterDrivers drivers: Set<String>) -> [String: String] {
        var configuration: [String: String] = [:]
        for driver in drivers {
            for command in filterCommands { configuration["filter.\(driver).\(command)"] = "" }
            configuration["filter.\(driver).required"] = "false"
        }
        return configuration
    }
}
