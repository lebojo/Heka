import Foundation
import Synchronization

struct AgentJournal: Equatable, Sendable {
    let source: SessionChatSource
    let url: URL
    var isSubagent = false
    var sessionID: String? = nil
    var directory: String? = nil
    var launchOptions = AgentOptionsReport()
    var launchedAt = Date.distantPast

    var refreshInterval: Duration? {
        switch source {
        case .openCode: .seconds(1)
        case .terminal: nil
        case .claude, .codex, .copilot: isSubagent ? nil : .seconds(10)
        }
    }

    var settingsFiles: [URL] {
        guard source == .claude, !isSubagent else { return [] }
        return ClaudeSettings.files(configDirectory: ClaudeTranscript.configDirectory(ofJournal: url), projectDirectory: directory)
    }

    func makeReader() -> @Sendable (URL) async -> ChatJournalRead {
        switch source {
        case .claude where isSubagent: Self.reader(decoding: ClaudeSubagentChatDecoder.self)
        case .claude: Self.claudeReader(settings: ClaudeSettings(configDirectory: ClaudeTranscript.configDirectory(ofJournal: url),
                                                                  projectDirectory: directory), launchOptions: launchOptions)
        case .codex: Self.reader(decoding: CodexChatDecoder.self)
        case .copilot: Self.reader(decoding: CopilotChatDecoder.self)
        case .openCode:
            Self.openCodeReader(sessionID: sessionID ?? "")
        case .terminal: { _ in ChatJournalRead(messages: []) }
        }
    }

    private static func openCodeReader(sessionID: String) -> @Sendable (URL) async -> ChatJournalRead {
        let reader = OpenCodeChatReader(sessionID: sessionID)
        return { ChatJournalRead(messages: await reader.read($0)) }
    }

    private static func claudeReader(settings: ClaudeSettings, launchOptions: AgentOptionsReport) -> @Sendable (URL) async -> ChatJournalRead {
        let read = reader(decoding: ClaudeChatDecoder.self)
        let attachedSize = Mutex<UInt64?>(nil)
        return { url in
            let boundary = attachedSize.withLock { size in
                if let size { return size }
                let current = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.size] as? UInt64 ?? 0
                size = current
                return current
            }
            var journal = await read(url)
            journal.options = journal.options.launched(withRecordsFrom: boundary, options: launchOptions)
            if journal.options.model == nil || journal.options.effort == nil {
                journal.defaults = launchOptions.filling(await settings.agentOptions())
            }
            return journal
        }
    }

    private static func reader<Decoder: ChatJournalDecoder>(decoding: Decoder.Type) -> @Sendable (URL) async -> ChatJournalRead {
        let reader = ChatJournalReader<Decoder>()
        return { url in
            let messages = await reader.read(url)
            return ChatJournalRead(messages: messages, options: await reader.options)
        }
    }
}

@MainActor final class AgentJournalMonitor {
    private let transcript: SessionTranscript
    private var attached: AgentJournal?
    private var read: (@Sendable (URL) async -> ChatJournalRead)?
    private var fileWatch: FileSystemWatcher?
    private var settingsWatches: [URL: FileSystemWatcher] = [:]
    private var watchRetry: Task<Void, Never>?
    private var refresh: Task<Void, Never>?
    private var reading: Task<Void, Never>?
    private var readAgain = false
    private var isSuspended = false
    private var generation = UUID()

    init(transcript: SessionTranscript) {
        self.transcript = transcript
    }

    func attach(_ journal: AgentJournal?) {
        guard journal != attached else {
            if isSuspended { resume() }
            return
        }
        let previous = attached
        stopWatching()
        attached = journal
        read = journal?.makeReader()
        isSuspended = false
        guard journal != nil else {
            if let previous, transcript.source == previous.source { transcript.useTerminal() }
            return
        }
        resume()
    }

    func suspend() {
        guard attached != nil, !isSuspended else { return }
        stopWatching()
        isSuspended = true
    }

    private func resume() {
        isSuspended = false
        installFileWatch()
        scheduleRead()
        _ = syncSettingsWatches()
        guard let interval = attached?.refreshInterval else { return }
        refresh = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: interval) } catch { return }
                guard let self else { return }
                _ = syncSettingsWatches()
                scheduleRead()
            }
        }
    }

    private func stopWatching() {
        generation = UUID()
        fileWatch?.cancel(); fileWatch = nil
        cancelSettingsWatches()
        watchRetry?.cancel(); watchRetry = nil
        refresh?.cancel(); refresh = nil
        reading?.cancel(); reading = nil
        readAgain = false
    }

    private func installFileWatch() {
        guard let attached else { return }
        let target = Self.nearestExistingItem(at: attached.url)
        let watchesJournal = target == attached.url
        fileWatch = try? FileSystemWatcher(target, events: [.write, .extend, .rename, .delete], queue: .main) { [weak self] event in
            let movesTarget = !watchesJournal || !event.isDisjoint(with: [.rename, .delete])
            MainActor.assumeIsolated { self?.changed(movingTarget: movesTarget) }
        }
        if fileWatch == nil { retryFileWatch() }
    }

    private func syncSettingsWatches() -> Bool {
        let targets = settingsTargets()
        let previous = Set(settingsWatches.keys)
        for url in previous.subtracting(targets) { settingsWatches.removeValue(forKey: url)?.cancel() }
        for url in targets where settingsWatches[url] == nil {
            settingsWatches[url] = try? FileSystemWatcher(url, events: [.write, .extend, .rename, .delete], queue: .main) { [weak self] event in
                let replacesItem = !event.isDisjoint(with: [.rename, .delete])
                MainActor.assumeIsolated { self?.settingsChanged(at: url, replacingItem: replacesItem) }
            }
        }
        return Set(settingsWatches.keys) != previous
    }

    private func settingsTargets() -> Set<URL> {
        guard let attached else { return [] }
        let files = attached.settingsFiles.filter { FileManager.default.fileExists(atPath: $0.path) }
        let folders = attached.settingsFiles.map { Self.nearestExistingItem(at: $0.deletingLastPathComponent()) }
        return Set(files + folders)
    }

    private func cancelSettingsWatches() {
        settingsWatches.values.forEach { $0.cancel() }
        settingsWatches = [:]
    }

    private func settingsChanged(at url: URL, replacingItem: Bool) {
        let isSettingsFile = attached?.settingsFiles.contains(url) == true
        if replacingItem { settingsWatches.removeValue(forKey: url)?.cancel() }
        if syncSettingsWatches() || isSettingsFile { scheduleRead() }
    }

    private func changed(movingTarget: Bool) {
        if movingTarget {
            fileWatch?.cancel(); fileWatch = nil
            installFileWatch()
        }
        scheduleRead()
    }

    private func retryFileWatch() {
        let token = generation
        watchRetry = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(1)) } catch { return }
            guard let self, generation == token, fileWatch == nil else { return }
            watchRetry = nil
            installFileWatch()
            scheduleRead()
        }
    }

    private static func nearestExistingItem(at url: URL) -> URL {
        var candidate = url
        while !FileManager.default.fileExists(atPath: candidate.path), candidate.pathComponents.count > 1 {
            candidate = candidate.deletingLastPathComponent()
        }
        return candidate
    }

    private func scheduleRead() {
        guard let attached, let read else { return }
        if reading != nil { readAgain = true; return }
        let token = generation
        reading = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(100)) } catch { return }
            let journal = await read(attached.url)
            guard let self, !Task.isCancelled, generation == token else { return }
            reading = nil
            transcript.useJournal(journal, from: attached.source)
            if readAgain { readAgain = false; scheduleRead() }
        }
    }
}
