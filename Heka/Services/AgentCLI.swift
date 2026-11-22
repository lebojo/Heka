import Foundation

enum AgentCLI {
    static let help = String(localized: """
    heka — organize the terminals and worktrees of the running app

    heka list
    heka project add /path/to/project
    heka terminal create [--name NAME] [--project UUID] [--worktree UUID] [-- COMMAND ARGUMENTS…]
    heka worktree create --branch BRANCH [--name NAME] [--project UUID] [--group UUID|NAME] [-- COMMAND ARGUMENTS…]
    heka worktree delete --worktree UUID [--delete-branch [--force-branch]] [--force]
    heka terminal send --terminal UUID [--enter] (-- TEXT… | --stdin)
    heka terminal send --terminal UUID --key KEY [--key KEY…]
    heka terminal read --terminal UUID [--lines N | --reply | --messages N]
    heka terminal wait --terminal UUID [--idle SECONDS | --exit] [--timeout SECONDS]
    heka terminal close --terminal UUID [--force]
    heka group create --name NAME [--project UUID] [--worktree UUID…]
    heka group add --group UUID|NAME --worktree UUID [--worktree UUID…]
    heka group remove --group UUID|NAME --worktree UUID [--worktree UUID…]
    heka group delete --group UUID|NAME

    From a Heka terminal, the project and worktree are implicit.
    Elsewhere, they are inferred from the current folder if it belongs to a project open in Heka.
    Child commands are passed as arguments, without shell interpretation.
    Examples:
      heka terminal create --name Review -- claude "Review the changes"
      heka worktree create --branch feature/tests -- codex "Add the tests"
    Each creation returns the identifiers and path as JSON.
    An existing branch is opened as is; otherwise it is created from the project’s HEAD.
    worktree delete closes its terminals and erases its folder; by default, the branch and its commits stay in the repository.
    With --delete-branch, the branch is deleted too if it’s merged into the repository’s main branch; otherwise nothing is removed. Add --force-branch to delete it even if it isn’t, losing its unmerged commits.
    The repository’s main branch and a branch checked out elsewhere are never deleted.
    Without --force, a worktree with uncommitted changes or untracked files, or with an agent working in another terminal, is kept; --force never deletes an unmerged branch.
    A project’s main folder can’t be deleted. From its own worktree, the command replies once everything is checked, then closes the current terminal and deletes the worktree.
    terminal send types TEXT into another terminal, or the standard input with --stdin. With --enter, the text is submitted as one message, like pressing Return; --enter alone just presses Return.
    --key presses keys one after the other, in order: enter, escape, tab, shift-tab, backspace, delete, space, up, down, left, right, home, end, page-up, page-down, ctrl-a … ctrl-z.
    terminal read prints the last lines of a terminal (50 by default, 10,000 at most) as output.
    For Claude, Codex, Copilot and OpenCode, --reply prints instead the agent’s answer to the last message as output, and --messages N the last N messages of its conversation (200 at most) as messages.
    terminal wait returns once the terminal has printed nothing for --idle SECONDS (5 by default), or once its command has exited with --exit. It gives up after --timeout SECONDS (120 by default, 3,600 at most) with ok: false.
    Their replies include running, exitCode and, for a recognized agent, agent and status (working, ready or waitingForInput).
    terminal close stops the terminal’s processes and removes it. Without --force, it refuses while its agent is working. The current terminal closes itself after the reply.
    The current terminal can’t send to or wait for itself.
    worktree create --group puts the new worktree in that group of its project; a group given by name is created if it doesn’t exist.
    group create makes a worktree group in the project of --project, of the given worktrees, or the current one, and moves the given worktrees into it. If the project already has a group with that name, it is reused.
    A group given by name is looked up in the project of the given worktrees, or the current one; a group UUID is found in any project. A project’s main folder can’t be grouped.
    group delete removes only the group: its worktrees stay, outside any group. Replies include groupID.
    """)

    static func run(arguments: [String]) -> Int32 {
        if arguments.isEmpty || arguments == ["--help"] || arguments == ["help"] {
            print(help)
            return 0
        }
        do {
            let environment = ProcessInfo.processInfo.environment
            let directory = try instanceDirectory(environment: environment)
            var request = try parse(arguments, environment: environment, currentDirectory: FileManager.default.currentDirectoryPath)
            if request.action == "terminal.send", request.text == nil, arguments.contains("--stdin") { request.text = try standardInput() }
            request.callerProcessID = getpid()
            let requestURL = directory.appendingPathComponent("\(request.id.uuidString).request")
            let responseURL = directory.appendingPathComponent("\(request.id.uuidString).response")
            defer { try? FileManager.default.removeItem(at: responseURL) }
            let changes = DispatchSemaphore(value: 0)
            let watcher = try? FileSystemWatcher(directory, queue: .global(qos: .userInitiated)) { _ in changes.signal() }
            defer { watcher?.cancel() }
            let recheck: DispatchTimeInterval = watcher == nil ? .milliseconds(50) : .seconds(1)
            try send(request, to: requestURL)
            let deadline = DispatchTime.now() + request.responseTimeout
            while DispatchTime.now() < deadline {
                if FileManager.default.fileExists(atPath: responseURL.path) {
                    let data = try BridgeMailbox.contents(of: responseURL, as: .response)
                    let response = try JSONDecoder().decode(BridgeResponse.self, from: data)
                    print(String(decoding: data, as: UTF8.self))
                    return response.ok ? 0 : 1
                }
                if !FileManager.default.fileExists(atPath: directory.path) {
                    throw WorkspaceError(message: String(localized: "The app was closed before responding."))
                }
                _ = changes.wait(timeout: min(deadline, .now() + recheck))
            }
            throw WorkspaceError(message: String(localized: "Heka didn’t respond within \(Int(request.responseTimeout)) seconds. The operation may still be running; check heka list before trying again."))
        } catch {
            let response = BridgeResponse(ok: false, message: error.localizedDescription)
            if let data = try? JSONEncoder().encode(response) { print(String(decoding: data, as: UTF8.self)) }
            return 1
        }
    }

    private static func send(_ request: BridgeRequest, to file: URL) throws {
        do { try JSONEncoder().encode(request).write(to: file, options: .atomic) }
        catch { throw WorkspaceError(message: String(localized: "Couldn’t send the request to Heka: \(error.localizedDescription) If this command runs in a sandbox, run heka outside it.")) }
    }

    private static func standardInput() throws -> String {
        let data = FileHandle.standardInput.readDataToEndOfFile()
        guard let text = String(data: data, encoding: .utf8) else {
            throw WorkspaceError(message: String(localized: "The standard input isn’t UTF-8 text."))
        }
        return withoutFinalLineBreak(text)
    }

    static func withoutFinalLineBreak(_ text: String) -> String {
        guard let last = text.last, last == "\n" || last == "\r\n" else { return text }
        return String(text.dropLast())
    }

    static func instanceDirectory(environment: [String: String]) throws -> URL {
        if let instance = environment["HEKA_INSTANCE"], FileManager.default.fileExists(atPath: instance) {
            return URL(fileURLWithPath: instance)
        }
        guard let published = runningInstance(in: WorkspaceDisk.instancesDirectory) else {
            throw WorkspaceError(message: String(localized: "Heka isn’t open. Launch the app, then try again."))
        }
        return published
    }

    static func runningInstance(in registry: URL) -> URL? {
        liveInstances(in: registry).max { creationDate(of: $0) < creationDate(of: $1) }
    }

    @discardableResult static func liveInstances(in registry: URL) -> [URL] {
        let keys: [URLResourceKey] = [.creationDateKey, .isDirectoryKey]
        let entries = (try? FileManager.default.contentsOfDirectory(at: registry, includingPropertiesForKeys: keys)) ?? []
        return entries.filter { entry in
            guard let pid = pid_t(entry.lastPathComponent) else { return false }
            guard isRunning(pid) else {
                try? FileManager.default.removeItem(at: entry)
                return false
            }
            return (try? entry.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
        }
    }

    static func isRunning(_ pid: pid_t) -> Bool {
        pid > 0 && (kill(pid, 0) == 0 || errno == EPERM)
    }

    private static func creationDate(of url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
    }

    static func parse(_ arguments: [String], environment: [String: String], currentDirectory: String? = nil) throws -> BridgeRequest {
        var request = BridgeRequest(id: UUID(), action: "", projectID: environment["HEKA_PROJECT_ID"].flatMap(UUID.init(uuidString:)),
                                    worktreeID: environment["HEKA_WORKTREE_ID"].flatMap(UUID.init(uuidString:)), command: [])
        request.directory = currentDirectory
        request.callerTerminalID = environment["HEKA_TERMINAL_ID"].flatMap(UUID.init(uuidString:))
        if arguments == ["list"] { request.action = "list"; return request }
        if arguments.count == 3, arguments[0...1] == ["project", "add"] {
            request.action = "project.add"
            request.path = URL(fileURLWithPath: arguments[2]).standardizedFileURL.path
            return request
        }
        if arguments.count >= 2, ["send", "read", "wait", "close"].contains(arguments[1]), arguments[0] == "terminal" {
            return try parseTerminalCommand(arguments, into: request)
        }
        if arguments.count >= 2, arguments[0] == "group", ["create", "add", "remove", "delete"].contains(arguments[1]) {
            return try parseGroupCommand(arguments, into: request)
        }
        let commands = [["terminal", "create"], ["worktree", "create"], ["worktree", "delete"]]
        guard arguments.count >= 2, commands.contains(Array(arguments[0...1])) else {
            throw WorkspaceError(message: String(localized: "Unknown command. See heka --help."))
        }
        request.action = arguments[0] + "." + arguments[1]
        let isDeletion = request.action == "worktree.delete"
        let options = arguments.prefix { $0 != "--" }
        let explicitlyTargetsProject = options.contains("--project")
        if explicitlyTargetsProject || isDeletion { request.worktreeID = nil }
        if options.contains("--worktree") && !explicitlyTargetsProject { request.projectID = nil }
        var index = 2
        while index < arguments.count {
            let option = arguments[index]
            if option == "--" && !isDeletion { request.command = Array(arguments.dropFirst(index + 1)); break }
            if option == "--force" && isDeletion { request.force = true; index += 1; continue }
            if option == "--delete-branch" && isDeletion { request.deleteBranch = true; index += 1; continue }
            if option == "--force-branch" && isDeletion { request.forceBranch = true; index += 1; continue }
            guard index + 1 < arguments.count else { throw WorkspaceError(message: String(localized: "Missing value for \(option).")) }
            let value = arguments[index + 1]
            switch option {
            case "--name": request.name = value
            case "--branch": request.branch = value
            case "--group" where request.action == "worktree.create": request.group = try groupReference(value)
            case "--project":
                guard let id = UUID(uuidString: value) else { throw WorkspaceError(message: String(localized: "Invalid project UUID.")) }
                request.projectID = id
            case "--worktree":
                guard let id = UUID(uuidString: value) else { throw WorkspaceError(message: String(localized: "Invalid worktree UUID.")) }
                request.worktreeID = id
            default: throw WorkspaceError(message: String(localized: "Unknown option: \(option)"))
            }
            index += 2
        }
        if isDeletion {
            _ = try request.branchRemoval
            guard request.worktreeID != nil else {
                throw WorkspaceError(message: String(localized: "Specify the worktree to delete: --worktree UUID (see heka list)."))
            }
        }
        return request
    }

    private static func parseGroupCommand(_ arguments: [String], into base: BridgeRequest) throws -> BridgeRequest {
        var request = base
        request.action = "group." + arguments[1]
        request.worktreeID = nil
        var explicitlyTargetsProject = false
        var index = 2
        while index < arguments.count {
            let option = arguments[index]
            guard index + 1 < arguments.count else { throw WorkspaceError(message: String(localized: "Missing value for \(option).")) }
            let value = arguments[index + 1]
            switch (request.action, option) {
            case ("group.create", "--name"): request.name = value
            case ("group.create", "--project"):
                guard let id = UUID(uuidString: value) else { throw WorkspaceError(message: String(localized: "Invalid project UUID.")) }
                request.projectID = id
                explicitlyTargetsProject = true
            case ("group.create", "--worktree"), ("group.add", "--worktree"), ("group.remove", "--worktree"):
                guard let id = UUID(uuidString: value) else { throw WorkspaceError(message: String(localized: "Invalid worktree UUID.")) }
                request.worktreeIDs = (request.worktreeIDs ?? []) + [id]
            case ("group.add", "--group"), ("group.remove", "--group"), ("group.delete", "--group"): request.group = try groupReference(value)
            default: throw WorkspaceError(message: String(localized: "Unknown option: \(option)"))
            }
            index += 2
        }
        if request.worktreeIDs != nil, !explicitlyTargetsProject { request.projectID = nil }
        if request.action == "group.create" {
            guard !(request.name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) else {
                throw WorkspaceError(message: String(localized: "A group name is required: --name NAME."))
            }
        } else if request.group == nil {
            throw WorkspaceError(message: String(localized: "Specify the group: --group UUID or NAME (see heka list)."))
        }
        if ["group.add", "group.remove"].contains(request.action), request.worktreeIDs == nil {
            throw WorkspaceError(message: String(localized: "Specify the worktrees: --worktree UUID (see heka list)."))
        }
        return request
    }

    private static func groupReference(_ value: String) throws -> String {
        let reference = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !reference.isEmpty else { throw WorkspaceError(message: String(localized: "--group needs a group UUID or name.")) }
        return reference
    }

    private static func parseTerminalCommand(_ arguments: [String], into base: BridgeRequest) throws -> BridgeRequest {
        var request = base
        request.action = "terminal." + arguments[1]
        request.projectID = nil
        request.worktreeID = nil
        var readsInput = false
        var index = 2
        while index < arguments.count {
            let option = arguments[index]
            switch (request.action, option) {
            case ("terminal.send", "--"):
                request.text = arguments.dropFirst(index + 1).joined(separator: " ")
                index = arguments.count
                continue
            case ("terminal.send", "--enter"): request.pressesEnter = true; index += 1; continue
            case ("terminal.send", "--stdin"): readsInput = true; index += 1; continue
            case ("terminal.wait", "--exit"): request.waitsForExit = true; index += 1; continue
            case ("terminal.read", "--reply"): request.reply = true; index += 1; continue
            case ("terminal.close", "--force"): request.force = true; index += 1; continue
            default: break
            }
            guard index + 1 < arguments.count else { throw WorkspaceError(message: String(localized: "Missing value for \(option).")) }
            let value = arguments[index + 1]
            switch (request.action, option) {
            case (_, "--terminal"):
                guard let id = UUID(uuidString: value) else { throw WorkspaceError(message: String(localized: "Invalid terminal UUID.")) }
                request.terminalID = id
            case ("terminal.read", "--lines"):
                guard let lines = Int(value) else { throw BridgeRequest.invalidLines }
                request.lines = lines
            case ("terminal.read", "--messages"):
                guard let count = Int(value) else { throw BridgeRequest.invalidMessages }
                request.messages = count
            case ("terminal.send", "--key"):
                guard TerminalKey(name: value) != nil else { throw BridgeRequest.unknownKey(value) }
                request.keys = (request.keys ?? []) + [value]
            case ("terminal.wait", "--idle"):
                request.idleSeconds = try seconds(value, option: option)
            case ("terminal.wait", "--timeout"):
                request.timeoutSeconds = try seconds(value, option: option)
            default: throw WorkspaceError(message: String(localized: "Unknown option: \(option)"))
            }
            index += 2
        }
        guard let target = request.terminalID else {
            throw WorkspaceError(message: String(localized: "Specify the terminal: --terminal UUID (see heka list)."))
        }
        if request.keys != nil, request.text != nil || readsInput || request.pressesEnter == true {
            throw WorkspaceError(message: String(localized: "--key can’t be combined with text, --stdin or --enter. Send them in separate commands, or add --key enter."))
        }
        try request.validate()
        if readsInput, request.text != nil {
            throw WorkspaceError(message: String(localized: "Use either --stdin or text after --, not both."))
        }
        if request.action == "terminal.send", !readsInput, request.text?.isEmpty ?? true, request.pressesEnter != true, request.keys == nil {
            throw WorkspaceError(message: String(localized: "Nothing to send: add the text after --, --stdin, --enter or --key."))
        }
        if target == request.callerTerminalID, ["terminal.send", "terminal.wait"].contains(request.action) {
            throw WorkspaceError(message: String(localized: "This is the current terminal. Pass the UUID of another terminal."))
        }
        return request
    }

    private static func seconds(_ value: String, option: String) throws -> Double {
        guard let seconds = Double(value) else { throw BridgeRequest.invalidSeconds(option: option) }
        return seconds
    }
}
