import Foundation

enum LoginShell {
    struct Invocation: Equatable, Sendable {
        let executable: String
        let arguments: [String]
    }

    static let scriptRunner = "/bin/zsh"
    private static let posixShells: Set<String> = ["sh", "bash", "zsh", "dash", "ksh"]

    static func path(environment: [String: String] = ProcessInfo.processInfo.environment) -> String {
        let configured = environment["SHELL"] ?? scriptRunner
        return FileManager.default.isExecutableFile(atPath: configured) ? configured : scriptRunner
    }

    static func isPOSIX(_ shell: String) -> Bool {
        posixShells.contains(URL(fileURLWithPath: shell).lastPathComponent)
    }

    static func running(_ script: String, arguments: [String] = [], shell: String = path()) -> Invocation {
        Invocation(executable: isPOSIX(shell) ? shell : scriptRunner, arguments: ["-l", "-i", "-c", script] + arguments)
    }

    static func session(running command: [String], keepingShell: Bool, shell: String) -> Invocation {
        if command.isEmpty { return Invocation(executable: shell, arguments: ["-l"]) }
        if keepingShell { return running("\"$@\"; exec \"$0\" -l", arguments: [shell] + command, shell: shell) }
        return running("exec \"$@\"", arguments: ["heka"] + command, shell: shell)
    }

    static func terminalEnvironment(inheriting environment: [String: String]) -> [String: String] {
        environment.filter { !isInheritedSessionVariable($0.key) }
    }

    private static func isInheritedSessionVariable(_ name: String) -> Bool {
        if name == "CLAUDECODE" || name == "CLAUDE_PID" || name.hasPrefix("CLAUDE_CODE_") { return true }
        return name.hasPrefix("HEKA_") && name != "HEKA_STATE_DIRECTORY" && name != "HEKA_REAL_STATE"
    }

    static func variable(_ name: String) async -> String? {
        if let value = ProcessInfo.processInfo.environment[name], !value.isEmpty { return value }
        let marker = "HEKA-\(UUID().uuidString)"
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let shell = running("printf '%s' \"$1\"; printenv \"$2\"", arguments: ["heka", marker, name])
        guard let data = try? await CommandRunner.run(URL(fileURLWithPath: shell.executable), shell.arguments,
                                                      at: home, timeout: 10, limit: 65_536, readOnly: true) else { return nil }
        let output = String(decoding: data, as: UTF8.self)
        guard let range = output.range(of: marker, options: .backwards) else { return nil }
        let value = output[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
