import Foundation
import Darwin
import os

enum CommandRunner {
    enum OutputOverflow: Sendable {
        case stop, discard, truncate
    }

    private static let registry = Registry()
    private static let diagnosticLimit = 65_536
    private static let diagnosticSize = 4096
    private static let terminationGrace: DispatchTimeInterval = .seconds(2)

    static func terminateAll(within grace: Duration = .milliseconds(500)) { registry.terminateAll(within: grace) }

    struct Output: Sendable {
        let data: Data
        let isTruncated: Bool
    }

    enum ExitStatus: Equatable, Sendable {
        case exited(Int32)
        case signalled(Int32)

        init(waitStatus: Int32) {
            let signal = waitStatus & 0x7f
            self = signal == 0 ? .exited((waitStatus >> 8) & 0xff) : .signalled(signal)
        }

        var exitCode: Int32? {
            if case .exited(let code) = self { code } else { nil }
        }

        var failureMessage: String {
            switch self {
            case .exited(let code): String(localized: "The command failed (exit code \(code)).")
            case .signalled(let signal): String(localized: "The command was interrupted by signal \(signal) (\(String(cString: strsignal(signal)))).")
            }
        }
    }

    static func run(_ executable: URL, _ arguments: [String], at path: String,
                    timeout: TimeInterval, limit: Int, readOnly: Bool, overflow: OutputOverflow = .stop,
                    gitConfiguration: [String: String] = [:]) async throws -> Data {
        try await output(executable, arguments, at: path, timeout: timeout, limit: limit, readOnly: readOnly,
                         overflow: overflow, gitConfiguration: gitConfiguration).data
    }

    static func output(_ executable: URL, _ arguments: [String], at path: String,
                       timeout: TimeInterval, limit: Int, readOnly: Bool, overflow: OutputOverflow = .stop,
                       gitConfiguration: [String: String] = [:]) async throws -> Output {
        let job = Job()
        let id = UUID()
        registry.add(job, id: id)
        defer { registry.remove(id) }
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            return try await execute(job, executable: executable, arguments: arguments, at: path, timeout: timeout, limit: limit,
                                     readOnly: readOnly, overflow: overflow, gitConfiguration: gitConfiguration)
        } onCancel: { job.stop(.cancelled) }
    }

    static func environment(readOnly: Bool, gitConfiguration: [String: String] = [:],
                            base: [String: String] = ProcessInfo.processInfo.environment) -> [String: String] {
        var environment = base
        environment["GIT_TERMINAL_PROMPT"] = "0"
        if readOnly {
            environment["GIT_OPTIONAL_LOCKS"] = "0"
            environment["GIT_NO_LAZY_FETCH"] = "1"
            environment["GIT_ALLOW_PROTOCOL"] = ""
        }
        environment["GH_PROMPT_DISABLED"] = "1"
        environment["GH_PAGER"] = "cat"
        environment["NO_COLOR"] = "1"
        environment.removeValue(forKey: "GH_DEBUG")
        return GitConfiguration.appending(gitConfiguration.merging(GitConfiguration.hardened) { $1 }, to: environment)
    }

    @concurrent private static func execute(_ job: Job, executable: URL, arguments: [String], at path: String,
                                            timeout: TimeInterval, limit: Int, readOnly: Bool, overflow: OutputOverflow,
                                            gitConfiguration: [String: String]) async throws -> Output {
        let outPipe = try CapturePipe()
        let errPipe: CapturePipe
        do { errPipe = try CapturePipe() } catch { outPipe.close(); throw error }
        let pid: pid_t
        do {
            pid = try job.start(executable: executable.path, arguments: arguments,
                                environment: environment(readOnly: readOnly, gitConfiguration: gitConfiguration),
                                directory: path, output: outPipe.writeEnd, error: errPipe.writeEnd)
        } catch {
            outPipe.close(); errPipe.close()
            throw error
        }
        outPipe.closeWriteEnd(); errPipe.closeWriteEnd()
        let queue = DispatchQueue(label: "Heka.command", qos: .utility)
        let keepsTail = overflow == .discard
        let output = OSAllocatedUnfairLock(initialState: Capture(capacity: keepsTail ? diagnosticSize : limit + 1, keepsTail: keepsTail))
        let errors = OSAllocatedUnfairLock(initialState: Capture(capacity: diagnosticSize, keepsTail: keepsTail))
        let outSource = capture(outPipe.readEnd, into: output, on: queue), errSource = capture(errPipe.readEnd, into: errors, on: queue)
        let timer = DispatchSource.makeTimerSource(queue: queue)
        let deadline = DispatchTime.now() + timeout
        let diagnosticLimit = Self.diagnosticLimit
        timer.schedule(deadline: .now() + .milliseconds(50), repeating: .milliseconds(50))
        timer.setEventHandler {
            job.killIfStillRunning(after: terminationGrace)
            let outOverflows = output.withLock { $0.total } > limit
            let errOverflows = readOnly && errors.withLock { $0.total } > diagnosticLimit
            switch overflow {
            case .discard: break
            case .truncate where outOverflows: return job.stop(.truncated)
            default: if outOverflows || errOverflows { return job.stop(.outputLimit) }
            }
            if DispatchTime.now() >= deadline { job.stop(.timeout) }
        }
        timer.resume()
        if await !waitForExit(of: pid, on: queue) { job.stop(.waitFailure) }
        timer.cancel()
        queue.sync {
            drainRemaining(outSource, descriptor: outPipe.readEnd, into: output)
            drainRemaining(errSource, descriptor: errPipe.readEnd, into: errors)
            outSource.cancel()
            errSource.cancel()
        }
        var status: Int32 = 0
        let isTruncated = try job.finish(status: &status)
        let out = output.withLock { $0 }
        guard out.total <= limit || overflow != .stop else { throw ReadCommandError(message: String(localized: "The output exceeds the display limit. Open this content in your editor.")) }
        guard status == 0 || isTruncated else {
            let errorText = diagnostic(errors.withLock { $0 }, fromEnd: keepsTail)
            let diagnostic = errorText.isEmpty ? diagnostic(out, fromEnd: true) : errorText
            throw ReadCommandError(message: diagnostic.isEmpty ? ExitStatus(waitStatus: status).failureMessage : diagnostic)
        }
        return Output(data: Data(out.data.prefix(limit)), isTruncated: isTruncated || out.total > limit)
    }

    private static func diagnostic(_ capture: Capture, fromEnd: Bool) -> String {
        let bytes = fromEnd ? capture.data.suffix(diagnosticSize) : capture.data.prefix(diagnosticSize)
        return String(decoding: bytes, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func capture(_ descriptor: Int32, into capture: OSAllocatedUnfairLock<Capture>, on queue: DispatchQueue) -> DispatchSourceRead {
        let source = DispatchSource.makeReadSource(fileDescriptor: descriptor, queue: queue)
        source.setEventHandler {
            if readChunk(from: descriptor, into: capture) == .end { source.cancel() }
        }
        source.setCancelHandler { Darwin.close(descriptor) }
        source.resume()
        return source
    }

    private static func drainRemaining(_ source: DispatchSourceRead, descriptor: Int32, into capture: OSAllocatedUnfairLock<Capture>) {
        guard !source.isCancelled else { return }
        var reads = 0
        while reads < 16, readChunk(from: descriptor, into: capture) == .data { reads += 1 }
    }

    private enum ChunkRead { case data, empty, end }

    private static func readChunk(from descriptor: Int32, into capture: OSAllocatedUnfairLock<Capture>) -> ChunkRead {
        var buffer = [UInt8](repeating: 0, count: 65_536)
        let count = read(descriptor, &buffer, buffer.count)
        if count > 0 {
            let chunk = buffer[..<count]
            capture.withLock { $0.append(chunk) }
            return .data
        }
        return count < 0 && (errno == EAGAIN || errno == EINTR) ? .empty : .end
    }

    private static func waitForExit(of pid: pid_t, on queue: DispatchQueue) async -> Bool {
        await withCheckedContinuation { continuation in
            let observation = ExitObservation()
            let source = DispatchSource.makeProcessSource(identifier: pid, eventMask: .exit, queue: queue)
            source.setEventHandler { source.cancel() }
            source.setCancelHandler { continuation.resume(returning: !observation.failed) }
            source.resume()
            queue.async {
                switch exitState(of: pid) {
                case .running: break
                case .exited: source.cancel()
                case .failed: observation.failed = true; source.cancel()
                }
            }
        }
    }

    private enum ExitState { case running, exited, failed }

    private static func exitState(of pid: pid_t) -> ExitState {
        var info = siginfo_t()
        var result: Int32
        repeat { result = waitid(P_PID, id_t(pid), &info, WEXITED | WNOWAIT | WNOHANG) } while result == -1 && errno == EINTR
        if result == -1 { return .failed }
        return info.si_pid == pid ? .exited : .running
    }

    private final class ExitObservation: @unchecked Sendable {
        var failed = false
    }

    private enum StopReason { case cancelled, quit, timeout, outputLimit, truncated, waitFailure }

    private struct Capture: Sendable {
        let capacity: Int
        let keepsTail: Bool
        private(set) var data = Data()
        private(set) var total = 0

        init(capacity: Int, keepsTail: Bool) {
            self.capacity = capacity
            self.keepsTail = keepsTail
        }

        mutating func append(_ chunk: ArraySlice<UInt8>) {
            total += chunk.count
            if keepsTail {
                data.append(contentsOf: chunk)
                if data.count > capacity { data = Data(data.suffix(capacity)) }
            } else if data.count < capacity {
                data.append(contentsOf: chunk.prefix(capacity - data.count))
            }
        }
    }

    private struct CapturePipe {
        let readEnd: Int32
        let writeEnd: Int32

        init() throws {
            var descriptors: [Int32] = [-1, -1]
            guard pipe(&descriptors) == 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
            descriptors.forEach { _ = fcntl($0, F_SETFD, FD_CLOEXEC) }
            _ = fcntl(descriptors[0], F_SETFL, O_NONBLOCK)
            readEnd = descriptors[0]
            writeEnd = descriptors[1]
        }

        func closeWriteEnd() { Darwin.close(writeEnd) }

        func close() {
            Darwin.close(readEnd)
            Darwin.close(writeEnd)
        }
    }

    private final class Registry: Sendable {
        private let jobs = OSAllocatedUnfairLock<[UUID: Job]>(initialState: [:])
        func add(_ job: Job, id: UUID) { jobs.withLock { $0[id] = job } }
        func remove(_ id: UUID) { _ = jobs.withLock { $0.removeValue(forKey: id) } }
        func terminateAll(within grace: Duration) {
            let active = jobs.withLock { Array($0.values) }
            active.forEach { $0.stop(.quit) }
            let deadline = ContinuousClock.now + grace
            while active.contains(where: \.isRunning), ContinuousClock.now < deadline { usleep(10_000) }
            active.forEach { $0.forceStop() }
        }
    }

    private final class Job: @unchecked Sendable {
        private let lock = NSLock()
        private var pid: pid_t?
        private var reason: StopReason?
        private var stoppedAt: DispatchTime?
        private var killed = false
        private var finished = false

        func start(executable: String, arguments: [String], environment: [String: String], directory: String,
                   output: Int32, error: Int32) throws -> pid_t {
            lock.lock()
            defer { lock.unlock() }
            if reason != nil { throw CancellationError() }
            var actions: posix_spawn_file_actions_t?
            var attributes: posix_spawnattr_t?
            try checked(posix_spawn_file_actions_init(&actions))
            defer { posix_spawn_file_actions_destroy(&actions) }
            try checked(posix_spawnattr_init(&attributes))
            defer { posix_spawnattr_destroy(&attributes) }
            try checked(posix_spawn_file_actions_addopen(&actions, STDIN_FILENO, "/dev/null", O_RDONLY, 0))
            try checked(posix_spawn_file_actions_adddup2(&actions, output, STDOUT_FILENO))
            try checked(posix_spawn_file_actions_adddup2(&actions, error, STDERR_FILENO))
            if #available(macOS 26, *) {
                try checked(posix_spawn_file_actions_addchdir(&actions, directory))
            } else {
                try checked(posix_spawn_file_actions_addchdir_np(&actions, directory))
            }
            try checked(posix_spawnattr_setpgroup(&attributes, 0))
            var unblocked = sigset_t(), defaulted = sigset_t()
            sigemptyset(&unblocked)
            sigemptyset(&defaulted)
            [SIGTERM, SIGINT, SIGHUP, SIGQUIT, SIGPIPE].forEach { sigaddset(&defaulted, $0) }
            try checked(posix_spawnattr_setsigmask(&attributes, &unblocked))
            try checked(posix_spawnattr_setsigdefault(&attributes, &defaulted))
            try checked(posix_spawnattr_setflags(&attributes, Int16(POSIX_SPAWN_SETPGROUP | POSIX_SPAWN_SETSIGMASK | POSIX_SPAWN_SETSIGDEF
                                                                   | POSIX_SPAWN_CLOEXEC_DEFAULT)))
            let argv = ([executable] + arguments).map { strdup($0) } + [nil]
            let env = environment.map { strdup("\($0.key)=\($0.value)") } + [nil]
            defer { argv.forEach { free($0) }; env.forEach { free($0) } }
            var child: pid_t = 0
            let result = argv.withUnsafeBufferPointer { args in
                env.withUnsafeBufferPointer { environment in
                    posix_spawn(&child, executable, &actions, &attributes, args.baseAddress!, environment.baseAddress!)
                }
            }
            try checked(result)
            pid = child
            return child
        }

        func stop(_ reason: StopReason) {
            lock.lock()
            defer { lock.unlock() }
            guard !finished else { return }
            if self.reason == nil {
                self.reason = reason
                stoppedAt = .now()
                if let pid { kill(-pid, SIGTERM) }
            }
            if reason == .waitFailure { killGroup() }
        }

        var isRunning: Bool {
            lock.lock()
            defer { lock.unlock() }
            guard !finished, let pid else { return false }
            return exitState(of: pid) == .running
        }

        func forceStop() {
            lock.lock()
            defer { lock.unlock() }
            guard !finished else { return }
            killGroup()
        }

        func killIfStillRunning(after grace: DispatchTimeInterval) {
            lock.lock()
            defer { lock.unlock() }
            guard !finished, let stoppedAt, DispatchTime.now() >= stoppedAt + grace else { return }
            killGroup()
        }

        private func killGroup() {
            guard !killed, let pid else { return }
            killed = true
            kill(-pid, SIGKILL)
        }

        func finish(status: inout Int32) throws -> Bool {
            lock.lock()
            defer { lock.unlock() }
            if reason != nil { killGroup() }
            if let pid {
                var result: pid_t
                repeat { result = waitpid(pid, &status, 0) } while result == -1 && errno == EINTR
            }
            finished = true
            pid = nil
            switch reason {
            case .cancelled, .quit: throw CancellationError()
            case .timeout: throw ReadCommandError(message: String(localized: "The command didn’t respond in time. The operation was interrupted."))
            case .outputLimit: throw ReadCommandError(message: String(localized: "The output exceeds the display limit. The operation was interrupted."))
            case .waitFailure: throw ReadCommandError(message: String(localized: "Couldn’t follow the command. The operation was interrupted."))
            case .truncated: return true
            case nil: return false
            }
        }

        private func checked(_ result: Int32) throws {
            if result != 0 { throw POSIXError(POSIXErrorCode(rawValue: result) ?? .EIO) }
        }
    }
}
