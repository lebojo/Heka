import Foundation

actor ConversationIndex {
    static let shared = ConversationIndex()

    private struct Stamp: Equatable {
        let modified: Date
        let size: Int
    }

    private struct Cached<Value> {
        let stamp: Stamp
        let value: Value
    }

    private struct DirectoryListing {
        let modified: Date
        let rollouts: [URL]
        let directories: [URL]
    }

    struct RunningTimes: Sendable {
        var recheckDelay = Duration.seconds(15)
        var maximumAge = Duration.seconds(120)
    }

    private struct RunningCheck {
        let started: ContinuousClock.Instant
        let journals: [String: Date]
        let sessions: Set<String>

        var age: Duration { started.duration(to: .now) }

        func isCurrent(for journals: [String: Date], times: RunningTimes) -> Bool {
            guard age < times.maximumAge else { return false }
            return age < times.recheckDelay || (journals == self.journals && sessions.isEmpty)
        }
    }

    private struct RunningRun {
        let id = UUID()
        let started = ContinuousClock.now
        let task: Task<Set<String>?, Never>
    }

    private let home: URL
    private let claudeConfig: URL
    private var claudeCache: [String: Cached<ClaudeTranscript>] = [:]
    private var codexCache: [String: Cached<CodexRollout?>] = [:]
    private var codexListings: [String: DirectoryListing] = [:]
    private var codexTitles: Cached<[String: String]>?
    private var copilotCache: [String: Cached<CopilotWorkspace?>] = [:]
    private var copilotPromptCache: [String: Cached<String?>] = [:]
    private var openCodeCache: (stamps: [Stamp?], sessions: [OpenCodeSessions.Session])?
    private var runningChecks: [String: RunningCheck] = [:]
    private var runningRuns: [String: RunningRun] = [:]
    private let runningTimes: RunningTimes
    private let listRunningSessions: @Sendable (String) async -> Set<String>?

    init(home: URL = FileManager.default.homeDirectoryForCurrentUser,
         environment: [String: String] = ProcessInfo.processInfo.environment,
         runningTimes: RunningTimes = RunningTimes(),
         listRunningSessions: @escaping @Sendable (String) async -> Set<String>? = ConversationIndex.runningClaudeSessions(at:)) {
        self.home = home
        claudeConfig = ClaudeTranscript.configDirectory(home: home, environment: environment)
        self.runningTimes = runningTimes
        self.listRunningSessions = listRunningSessions
    }

    static var watchedDirectories: [String] { shared.watchedDirectories }

    nonisolated var watchedDirectories: [String] {
        [claudeConfig.appendingPathComponent("projects", isDirectory: true).path]
            + [".codex/sessions", ".copilot/session-state", ".local/share/opencode"].map { home.appendingPathComponent($0, isDirectory: true).path }
    }

    static func load(at path: String, fresh: Bool = false) async -> [AgentConversation] {
        await shared.load(at: path, fresh: fresh)
    }

    func load(at path: String, fresh: Bool) async -> [AgentConversation] {
        let conversations = conversations(at: path)
        let journals = Dictionary(conversations.filter { $0.agent == .claude }.map { ($0.sessionID, $0.updatedAt) }, uniquingKeysWith: max)
        let active = await runningSessions(at: path, journals: journals, fresh: fresh)
        return conversations.map { conversation in
            var conversation = conversation
            conversation.isRunning = conversation.agent == .claude && active.contains(conversation.sessionID)
            return conversation
        }
    }

    func conversations(at path: String) -> [AgentConversation] {
        (claudeConversations(at: path) + codexConversations(at: path) + copilotConversations(at: path) + openCodeConversations(at: path))
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    static func samePath(_ recorded: String?, _ path: String) -> Bool {
        recorded?.compare(path, options: .caseInsensitive) == .orderedSame
    }

    private func claudeConversations(at path: String) -> [AgentConversation] {
        ClaudeTranscript.directories(for: path, in: claudeConfig.appendingPathComponent("projects", isDirectory: true)).flatMap { directory in
            let journals = Self.contents(of: directory).filter { $0.pathExtension == "jsonl" }
            Self.prune(&claudeCache, under: directory, keeping: journals)
            return journals.compactMap { url -> AgentConversation? in
                guard let stamp = Self.stamp(url) else { return nil }
                let transcript = claudeTranscript(url, stamp: stamp)
                guard Self.samePath(transcript.cwd, path), let title = transcript.title else { return nil }
                return AgentConversation(agent: .claude, sessionID: url.deletingPathExtension().lastPathComponent,
                                         title: title, updatedAt: stamp.modified)
            }
        }
    }

    private func claudeTranscript(_ url: URL, stamp: Stamp) -> ClaudeTranscript {
        let previous = claudeCache[url.path]
        if let previous, previous.stamp == stamp { return previous.value }
        let continued = previous.flatMap { $0.stamp.size <= stamp.size ? $0.value : nil }
        let transcript = ClaudeTranscript.read(url, continuing: continued)
        claudeCache[url.path] = Cached(stamp: stamp, value: transcript)
        return transcript
    }

    private func codexConversations(at path: String) -> [AgentConversation] {
        let codex = home.appendingPathComponent(".codex", isDirectory: true)
        let sessions = codex.appendingPathComponent("sessions", isDirectory: true)
        let rollouts = rolloutFiles(in: sessions)
        Self.prune(&codexCache, under: sessions, keeping: rollouts)
        var found: [String: AgentConversation] = [:]
        var titles: [String: String]?
        for url in rollouts {
            if let known = codexCache[url.path]?.value ?? nil, !Self.samePath(known.cwd, path) { continue }
            guard let stamp = Self.stamp(url),
                  let rollout = cached(url, stamp: stamp, in: &codexCache, read: { CodexRollout.read(url) }),
                  Self.samePath(rollout.cwd, path) else { continue }
            if titles == nil { titles = codexThreadNames(in: codex.appendingPathComponent("session_index.jsonl")) }
            if let existing = found[rollout.sessionID], existing.updatedAt >= stamp.modified { continue }
            let title = titles?[rollout.sessionID] ?? rollout.firstPrompt ?? String(localized: "Codex Conversation")
            found[rollout.sessionID] = AgentConversation(agent: .codex, sessionID: rollout.sessionID, title: title, updatedAt: stamp.modified)
        }
        return Array(found.values)
    }

    private func rolloutFiles(in sessions: URL) -> [URL] {
        var rollouts: [URL] = []
        var visited: Set<String> = []
        var pending = [sessions]
        while let directory = pending.popLast() {
            guard let listing = codexListing(of: directory) else { continue }
            visited.insert(directory.path)
            rollouts += listing.rollouts
            pending += listing.directories
        }
        codexListings = codexListings.filter { visited.contains($0.key) }
        return rollouts
    }

    private func codexListing(of directory: URL) -> DirectoryListing? {
        var directory = directory
        directory.removeAllCachedResourceValues()
        guard let values = try? directory.resourceValues(forKeys: [.contentModificationDateKey, .isDirectoryKey]),
              values.isDirectory == true, let modified = values.contentModificationDate else { return nil }
        if let listing = codexListings[directory.path], listing.modified == modified { return listing }
        let keys: [URLResourceKey] = [.isDirectoryKey, .isPackageKey]
        let entries = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: keys, options: .skipsHiddenFiles)) ?? []
        let directories = entries.filter { url in
            let values = try? url.resourceValues(forKeys: Set(keys))
            return values?.isDirectory == true && values?.isPackage != true
        }
        let rollouts = entries.filter { $0.lastPathComponent.hasPrefix("rollout-") && $0.pathExtension == "jsonl" }
        let listing = DirectoryListing(modified: modified, rollouts: rollouts, directories: directories)
        codexListings[directory.path] = listing
        return listing
    }

    private func codexThreadNames(in index: URL) -> [String: String] {
        guard let stamp = Self.stamp(index) else {
            codexTitles = nil
            return [:]
        }
        if let codexTitles, codexTitles.stamp == stamp { return codexTitles.value }
        let titles = CodexRollout.titles(in: index)
        codexTitles = Cached(stamp: stamp, value: titles)
        return titles
    }

    private func copilotConversations(at path: String) -> [AgentConversation] {
        let sessions = home.appendingPathComponent(".copilot/session-state", isDirectory: true)
        let directories = Self.contents(of: sessions)
        Self.prune(&copilotCache, under: sessions, keeping: directories.map { $0.appendingPathComponent("workspace.yaml") })
        Self.prune(&copilotPromptCache, under: sessions, keeping: directories.map { $0.appendingPathComponent("events.jsonl") })
        var found: [AgentConversation] = []
        for directory in directories {
            let workspaceURL = directory.appendingPathComponent("workspace.yaml")
            let events = directory.appendingPathComponent("events.jsonl")
            guard let workspaceStamp = Self.stamp(workspaceURL),
                  let workspace = cached(workspaceURL, stamp: workspaceStamp, in: &copilotCache, read: { CopilotWorkspace.read(workspaceURL) }),
                  Self.samePath(workspace.cwd, path) else { continue }
            let eventsStamp = Self.stamp(events)
            var title = workspace.title
            if title == nil, let eventsStamp {
                title = cached(events, stamp: eventsStamp, in: &copilotPromptCache) { CopilotWorkspace.firstPrompt(in: events) }
            }
            let updatedAt = max(workspaceStamp.modified, eventsStamp?.modified ?? .distantPast)
            found.append(AgentConversation(agent: .copilot, sessionID: directory.lastPathComponent,
                                           title: title ?? String(localized: "Copilot Conversation"), updatedAt: updatedAt))
        }
        return found
    }

    private func openCodeConversations(at path: String) -> [AgentConversation] {
        var found: [String: AgentConversation] = [:]
        for session in openCodeSessions() where Self.samePath(session.directory, path) {
            if let existing = found[session.id], existing.updatedAt >= session.updatedAt { continue }
            let title = ConversationTitle.clean(session.title) ?? String(localized: "OpenCode Conversation")
            found[session.id] = AgentConversation(agent: .openCode, sessionID: session.id, title: title, updatedAt: session.updatedAt)
        }
        return Array(found.values)
    }

    private func openCodeSessions() -> [OpenCodeSessions.Session] {
        let database = home.appendingPathComponent(".local/share/opencode/opencode.db")
        let stamps = [database, URL(fileURLWithPath: database.path + "-wal")].map(Self.stamp)
        if let openCodeCache, openCodeCache.stamps == stamps { return openCodeCache.sessions }
        guard let sessions = OpenCodeSessions.read(database) else { return openCodeCache?.sessions ?? [] }
        openCodeCache = (stamps, sessions)
        return sessions
    }

    private func cached<Value>(_ url: URL, stamp: Stamp, in cache: inout [String: Cached<Value>], read: () -> Value) -> Value {
        if let entry = cache[url.path], entry.stamp == stamp { return entry.value }
        let value = read()
        cache[url.path] = Cached(stamp: stamp, value: value)
        return value
    }

    private static func prune<Value>(_ cache: inout [String: Cached<Value>], under directory: URL, keeping urls: [URL]) {
        let prefix = directory.path + "/"
        let kept = Set(urls.map(\.path))
        cache = cache.filter { !$0.key.hasPrefix(prefix) || kept.contains($0.key) }
    }

    private static func contents(of directory: URL) -> [URL] {
        (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey, .isRegularFileKey])) ?? []
    }

    private static func stamp(_ url: URL) -> Stamp? {
        var url = url
        url.removeAllCachedResourceValues()
        guard let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey, .isRegularFileKey]),
              values.isRegularFile == true, let modified = values.contentModificationDate else { return nil }
        return Stamp(modified: modified, size: values.fileSize ?? 0)
    }

    func runningSessions(at path: String, journals: [String: Date], fresh: Bool) async -> Set<String> {
        let previous = runningChecks[path]
        if !fresh, let previous, previous.isCurrent(for: journals, times: runningTimes) { return previous.sessions }
        let run = runningRun(at: path, joining: !fresh)
        let sessions = await run.task.value ?? previous?.sessions ?? []
        if runningRuns[path]?.id == run.id { runningRuns[path] = nil }
        record(RunningCheck(started: run.started, journals: journals, sessions: sessions), at: path)
        return sessions
    }

    private func runningRun(at path: String, joining: Bool) -> RunningRun {
        if joining, let run = runningRuns[path] { return run }
        let list = listRunningSessions
        let run = RunningRun(task: Task { await list(path) })
        runningRuns[path] = run
        return run
    }

    private func record(_ check: RunningCheck, at path: String) {
        runningChecks = runningChecks.filter { $0.value.age < runningTimes.maximumAge }
        if let current = runningChecks[path], current.started > check.started { return }
        runningChecks[path] = check
    }

    static func runningClaudeSessions(at path: String) async -> Set<String>? {
        struct Session: Decodable {
            let sessionId: String
        }
        guard let claude = ReadCommand.executable("claude") else { return [] }
        guard let data = try? await ReadCommand.run(claude, ["agents", "--json", "--cwd", path], at: path, timeout: 5),
              let sessions = try? JSONDecoder().decode([Session].self, from: data) else { return nil }
        return Set(sessions.map(\.sessionId))
    }
}
