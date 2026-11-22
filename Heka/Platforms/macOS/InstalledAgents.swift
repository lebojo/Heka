import Foundation
import Observation

@MainActor @Observable final class InstalledAgents {
    private(set) var agents: [ConversationAgent] = []
    @ObservationIgnored private var detectedAt: ContinuousClock.Instant?
    @ObservationIgnored private var attemptedAt: ContinuousClock.Instant?

    func refresh() async {
        guard Self.isOlder(detectedAt, than: .seconds(600)), Self.isOlder(attemptedAt, than: .seconds(60)) else { return }
        await reload()
    }

    func reload() async {
        attemptedAt = .now
        guard let detected = await Self.detect() else { return }
        detectedAt = .now
        if agents != detected { agents = detected }
    }

    private static func isOlder(_ instant: ContinuousClock.Instant?, than interval: Duration) -> Bool {
        instant.map { $0.duration(to: .now) >= interval } ?? true
    }

    @concurrent private static func detect() async -> [ConversationAgent]? {
        let lookups = ConversationAgent.allCases.map { "command -v \($0.rawValue) >/dev/null 2>&1 && echo \($0.rawValue)" }
        let searchPath = await LoginShell.loadSearchPath()
        let shell = LoginShell.running((lookups + ["true"]).joined(separator: "; "), searchPath: searchPath)
        guard let output = try? await CommandRunner.run(URL(fileURLWithPath: shell.executable), shell.arguments, at: NSHomeDirectory(),
                                                        timeout: 15, limit: 65_536, readOnly: true) else { return nil }
        let names = Set(String(decoding: output, as: UTF8.self).split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) })
        return ConversationAgent.allCases.filter { names.contains($0.rawValue) }
    }
}
