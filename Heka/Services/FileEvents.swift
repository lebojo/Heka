import Foundation
import CoreServices

enum FileEvents {
    static let fallbackInterval: Duration = .seconds(5)
    static let repositoryLatency: Duration = .seconds(1)
    static let repositorySpacing: Duration = .seconds(3)

    static func changes(in paths: [String], latency: Duration, every interval: Duration? = nil) -> AsyncStream<Void> {
        let (stream, continuation) = AsyncStream.makeStream(of: Void.self, bufferingPolicy: .bufferingNewest(1))
        continuation.yield()
        let watcher = FileEventWatcher(paths: paths, latency: latency) { _ in continuation.yield() }
        let ticker = (interval ?? (watcher == nil ? fallbackInterval : nil)).map { ticks(every: $0, into: continuation) }
        continuation.onTermination = { _ in
            ticker?.cancel()
            watcher?.stop()
        }
        return stream
    }

    static func entries(of directories: [URL], every interval: Duration) -> AsyncStream<Void> {
        let (stream, continuation) = AsyncStream.makeStream(of: Void.self, bufferingPolicy: .bufferingNewest(1))
        continuation.yield()
        let queue = DispatchQueue(label: "Heka.directory-entries", qos: .utility)
        let watchers = directories.compactMap { try? FileSystemWatcher($0, queue: queue) { _ in continuation.yield() } }
        let ticker = ticks(every: interval, into: continuation)
        continuation.onTermination = { _ in
            ticker.cancel()
            watchers.forEach { $0.cancel() }
        }
        return stream
    }

    @concurrent static func repositoryChanges(at path: String) async -> AsyncStream<Void> {
        guard let repository = GitRepository.containing(path) else { return changes(in: [path], latency: repositoryLatency) }
        let paths = Array(Set([path, repository.gitDirectory.path, repository.commonDirectory.path]))
        let (batches, batch) = AsyncStream.makeStream(of: (arrival: ContinuousClock.Instant, paths: [String]).self)
        guard let watcher = FileEventWatcher(paths: paths, latency: repositoryLatency, onChange: { batch.yield((.now, $0)) }) else {
            return changes(in: paths, latency: repositoryLatency)
        }
        let (stream, continuation) = AsyncStream.makeStream(of: Void.self, bufferingPolicy: .bufferingNewest(1))
        continuation.yield()
        let filtering = Task {
            await deliverRelevant(batches, filter: RepositoryEventFilter(repository: repository), into: continuation)
        }
        continuation.onTermination = { _ in
            filtering.cancel()
            watcher.stop()
            batch.finish()
        }
        return stream
    }

    private static func deliverRelevant(_ batches: AsyncStream<(arrival: ContinuousClock.Instant, paths: [String])>, filter: RepositoryEventFilter,
                                        into continuation: AsyncStream<Void>.Continuation) async {
        var lastDelivery: ContinuousClock.Instant?
        for await batch in batches {
            if let lastDelivery, batch.arrival < lastDelivery { continue }
            guard await filter.isRelevant(batch.paths) else { continue }
            if let lastDelivery {
                do { try await Task.sleep(until: lastDelivery + repositorySpacing) } catch { return }
            }
            lastDelivery = .now
            continuation.yield()
        }
    }

    private static func ticks(every period: Duration, into continuation: AsyncStream<Void>.Continuation) -> Task<Void, Never> {
        Task {
            while !Task.isCancelled {
                do { try await Task.sleep(for: period) } catch { return }
                continuation.yield()
            }
        }
    }
}

final class FileEventWatcher: @unchecked Sendable {
    private let queue = DispatchQueue(label: "Heka.file-events", qos: .utility)
    private let onChange: @Sendable ([String]) -> Void
    private var stream: FSEventStreamRef?
    private var isStopped = false

    init?(paths: [String], latency: Duration, onChange: @escaping @Sendable ([String]) -> Void) {
        let existing = paths.filter { FileManager.default.fileExists(atPath: $0) }
        guard !existing.isEmpty else { return nil }
        self.onChange = onChange
        var context = FSEventStreamContext(version: 0, info: Unmanaged.passUnretained(self).toOpaque(),
                                           retain: nil, release: nil, copyDescription: nil)
        let flags = FSEventStreamCreateFlags(kFSEventStreamCreateFlagNoDefer | kFSEventStreamCreateFlagUseCFTypes)
        let seconds = Double(latency.components.seconds) + Double(latency.components.attoseconds) / 1e18
        guard let stream = FSEventStreamCreate(kCFAllocatorDefault, { _, info, _, eventPaths, _, _ in
            guard let info else { return }
            let paths = Unmanaged<CFArray>.fromOpaque(eventPaths).takeUnretainedValue() as? [String] ?? []
            Unmanaged<FileEventWatcher>.fromOpaque(info).takeUnretainedValue().deliver(paths)
        }, &context, existing as CFArray, FSEventStreamEventId(kFSEventStreamEventIdSinceNow), seconds, flags) else { return nil }
        FSEventStreamSetDispatchQueue(stream, queue)
        guard FSEventStreamStart(stream) else {
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            return nil
        }
        self.stream = stream
    }

    func stop() {
        queue.async { [self] in
            guard let stream else { return }
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            self.stream = nil
            isStopped = true
        }
    }

    private func deliver(_ paths: [String]) {
        guard !isStopped else { return }
        onChange(paths)
    }
}

actor RepositoryEventFilter {
    private enum Location {
        case relevant, irrelevant, worktree
    }

    private static let ignoredMetadata = ["objects/", "logs/", "worktrees/", "lfs/", "hooks/", "fsmonitor--daemon/"]
    private static let batchSize = 200

    private let root: String
    private let gitDirectory: String
    private let commonDirectory: String
    private var ignoredDirectories: Set<String> = []

    init(repository: GitRepository) {
        root = Self.directoryPath(repository.root.path)
        gitDirectory = Self.directoryPath(repository.gitDirectory.path)
        commonDirectory = Self.directoryPath(repository.commonDirectory.path)
    }

    func isRelevant(_ paths: [String]) async -> Bool {
        var candidates: Set<String> = []
        for path in paths.map(Self.directoryPath) {
            switch location(of: path) {
            case .relevant:
                ignoredDirectories.removeAll()
                return true
            case .irrelevant: continue
            case .worktree: if !isInsideIgnoredDirectory(path) { candidates.insert(path) }
            }
        }
        guard !candidates.isEmpty else { return false }
        let ignored = await Self.ignoredPaths(Array(candidates), at: root)
        guard candidates.isSubset(of: ignored) else {
            ignoredDirectories.removeAll()
            return true
        }
        ignoredDirectories.formUnion(ignored)
        return false
    }

    private func location(of path: String) -> Location {
        if path.hasPrefix(gitDirectory) { return Self.metadataLocation(String(path.dropFirst(gitDirectory.count))) }
        if path.hasPrefix(commonDirectory) { return Self.metadataLocation(String(path.dropFirst(commonDirectory.count))) }
        return path.hasPrefix(root) && path != root ? .worktree : .relevant
    }

    private func isInsideIgnoredDirectory(_ path: String) -> Bool {
        var index = path.index(path.startIndex, offsetBy: root.count)
        while let slash = path[index...].firstIndex(of: "/") {
            index = path.index(after: slash)
            if ignoredDirectories.contains(String(path[..<index])) { return true }
        }
        return false
    }

    private static func metadataLocation(_ relative: String) -> Location {
        ignoredMetadata.contains { relative.hasPrefix($0) } ? .irrelevant : .relevant
    }

    private static func directoryPath(_ path: String) -> String {
        path.hasSuffix("/") ? path : path + "/"
    }

    private static func ignoredPaths(_ paths: [String], at root: String) async -> Set<String> {
        var ignored: Set<String> = []
        for start in stride(from: 0, to: paths.count, by: batchSize) {
            let batch = Array(paths[start..<min(start + batchSize, paths.count)])
            guard let data = try? await ReadCommand.run(URL(fileURLWithPath: "/usr/bin/git"),
                                                        ["-c", "core.quotePath=false", "check-ignore", "--"] + batch,
                                                        at: root, timeout: 10) else { continue }
            ignored.formUnion(String(decoding: data, as: UTF8.self).split(separator: "\n").map(String.init))
        }
        return ignored
    }
}
