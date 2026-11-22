import Foundation
import os

enum LoginShell {
    struct Invocation: Equatable, Sendable {
        let executable: String
        let arguments: [String]
    }

    enum SessionShell: Equatable, Sendable {
        case none
        case plain
        case afterCommand

        init(command: [String], keepingShell: Bool) {
            if command.isEmpty { self = .plain } else { self = keepingShell ? .afterCommand : .none }
        }

        func isRunning(shellArguments: () -> [String]) -> Bool {
            switch self {
            case .none: false
            case .plain: true
            case .afterCommand: LoginShell.hasLeftCommand(shellArguments())
            }
        }
    }

    static let scriptRunner = "/bin/zsh"
    private static let posixShells: Set<String> = ["sh", "bash", "zsh", "dash", "ksh"]
    private static let cShells: Set<String> = ["csh", "tcsh"]
    private static let searchPaths = OSAllocatedUnfairLock<[String: String]>(initialState: [:])

    static func path(environment: [String: String] = ProcessInfo.processInfo.environment) -> String {
        let configured = environment["SHELL"] ?? scriptRunner
        return FileManager.default.isExecutableFile(atPath: configured) ? configured : scriptRunner
    }

    static func isPOSIX(_ shell: String) -> Bool {
        posixShells.contains(name(of: shell))
    }

    static func hasLeftCommand(_ shellArguments: [String]) -> Bool {
        !shellArguments.isEmpty && !shellArguments.contains("-c")
    }

    static func running(_ script: String, arguments: [String] = [], shell: String = path(), searchPath: String? = nil) -> Invocation {
        let runnerArguments = ["-l", "-i", "-c", script] + arguments
        if isPOSIX(shell) { return Invocation(executable: shell, arguments: runnerArguments) }
        guard let searchPath else { return Invocation(executable: scriptRunner, arguments: runnerArguments) }
        return Invocation(executable: "/usr/bin/env", arguments: ["PATH=" + searchPath, scriptRunner] + runnerArguments)
    }

    static func session(running command: [String], keepingShell: Bool, shell: String) -> Invocation {
        if command.isEmpty { return Invocation(executable: shell, arguments: ["-l"]) }
        if keepingShell { return running("\"$@\"; exec \"$0\" -l", arguments: [shell] + command, shell: shell) }
        return running("exec \"$@\"", arguments: ["heka"] + command, shell: shell)
    }

    static func terminalEnvironment(inheriting environment: [String: String]) -> [String: String] {
        environment.filter { !isInheritedSessionVariable($0.key) }
    }

    static func combinedPath(_ base: String?, adding shellPath: String?) -> String? {
        guard let shellPath else { return base }
        let added = shellPath.split(separator: ":").map(String.init)
        let kept = (base ?? "").split(separator: ":").map(String.init).filter { !added.contains($0) }
        return (kept + added).joined(separator: ":")
    }

    static func cachedSearchPath(shell: String) -> String? {
        searchPaths.withLock { $0[shell] }
    }

    static func loadSearchPath(shell: String = path()) async -> String? {
        guard !isPOSIX(shell), let value = await shellVariable("PATH", shell: shell) else { return nil }
        searchPaths.withLock { $0[shell] = value }
        return value
    }

    static func variableProbe(_ name: String, marker: String, shell: String) -> Invocation {
        guard !isPOSIX(shell) else { return running("printf '%s' \"$1\"; printenv \"$2\"", arguments: ["heka", marker, name], shell: shell) }
        let script = "echo \(marker); printenv \(name)"
        return Invocation(executable: shell, arguments: cShells.contains(self.name(of: shell)) ? ["-c", script] : ["-l", "-i", "-c", script])
    }

    static func value(after marker: String, in output: String) -> String? {
        guard let range = output.range(of: marker, options: .backwards) else { return nil }
        let value = output[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    static func variable(_ name: String) async -> String? {
        if let value = ProcessInfo.processInfo.environment[name], !value.isEmpty { return value }
        return await shellVariable(name, shell: path())
    }

    private static func shellVariable(_ name: String, shell: String) async -> String? {
        let marker = "HEKA-\(UUID().uuidString)"
        let probe = variableProbe(name, marker: marker, shell: shell)
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        guard let data = try? await CommandRunner.run(URL(fileURLWithPath: probe.executable), probe.arguments,
                                                      at: home, timeout: 10, limit: 65_536, readOnly: true) else { return nil }
        return value(after: marker, in: String(decoding: data, as: UTF8.self))
    }

    private static func name(of shell: String) -> String {
        URL(fileURLWithPath: shell).lastPathComponent
    }

    private static func isInheritedSessionVariable(_ name: String) -> Bool {
        if name == "CLAUDECODE" || name == "CLAUDE_PID" || name.hasPrefix("CLAUDE_CODE_") { return true }
        return name.hasPrefix("HEKA_") && name != "HEKA_STATE_DIRECTORY" && name != "HEKA_REAL_STATE"
    }
}
