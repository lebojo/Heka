import Foundation
import AppKit

@MainActor final class AgentBridge {
    let directory: URL
    private let store: WorkspaceStore
    private var watcher: FileSystemWatcher?
    private var active: Set<UUID> = []
    private var delivered: Set<UUID> = []

    init(store: WorkspaceStore) throws {
        self.store = store
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("heka-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        let bin = directory.appendingPathComponent("bin")
        try FileManager.default.createDirectory(at: bin, withIntermediateDirectories: true)
        try Self.installLauncher(at: bin.appendingPathComponent("heka"))
        store.sessions.environment = [
            "HEKA_INSTANCE": directory.path,
            "HEKA_CLI": bin.appendingPathComponent("heka").path,
            "PATH": bin.path + ":" + (ProcessInfo.processInfo.environment["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin")
        ]
        do {
            watcher = try FileSystemWatcher(directory, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.drain() }
            }
        } catch { throw WorkspaceError(message: String(localized: "Couldn’t set up the heka command.")) }
        #if DEBUG
        if ProcessInfo.processInfo.environment["HEKA_STATE_DIRECTORY"] != nil {
            let stateDirectory = WorkspaceDisk.applicationDirectory
            try FileManager.default.createDirectory(at: stateDirectory, withIntermediateDirectories: true)
            try directory.path.write(to: stateDirectory.appendingPathComponent("instance-path"), atomically: true, encoding: .utf8)
        }
        #endif
        publish()
    }

    private var registration: URL {
        WorkspaceDisk.instancesDirectory.appendingPathComponent(String(ProcessInfo.processInfo.processIdentifier))
    }

    func stop() {
        watcher?.cancel()
        watcher = nil
        try? FileManager.default.removeItem(at: directory)
        try? FileManager.default.removeItem(at: registration)
    }

    private func publish() {
        try? FileManager.default.createDirectory(at: WorkspaceDisk.instancesDirectory, withIntermediateDirectories: true)
        try? directory.path.write(to: registration, atomically: true, encoding: .utf8)
    }

    private func drain() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return }
        for file in files where file.pathExtension == "request" {
            guard let id = UUID(uuidString: file.deletingPathExtension().lastPathComponent), !active.contains(id) else { continue }
            active.insert(id)
            Task { await process(file, id: id) }
        }
    }

    private func process(_ file: URL, id: UUID) async {
        defer { active.remove(id); try? FileManager.default.removeItem(at: file) }
        let response: BridgeResponse
        do {
            let request = try await BridgeMailbox.request(at: file)
            guard request.id == id else { throw WorkspaceError(message: String(localized: "Invalid request ID.")) }
            var result = try await execute(request)
            if !Self.leavesWorkspaceUnchanged(request.action) {
                do { try await store.flushPersistence() }
                catch { result.ok = false; result.message = error.localizedDescription }
            }
            response = result
        } catch { response = BridgeResponse(ok: false, message: error.localizedDescription) }
        guard delivered.remove(id) == nil else {
            if !response.ok, let message = response.message { store.errorMessage = message }
            return
        }
        do {
            try await BridgeMailbox.write(response, to: responseFile(for: id))
        } catch { store.errorMessage = String(localized: "Couldn’t reply to heka: \(error.localizedDescription)") }
    }

    private func responseFile(for id: UUID) -> URL {
        directory.appendingPathComponent("\(id.uuidString).response")
    }

    private func replyBeforeClosingCaller(_ response: BridgeResponse, to id: UUID) async {
        var response = response
        response.closesCaller = true
        let file = responseFile(for: id)
        do { try await BridgeMailbox.write(response, to: file) } catch { return }
        delivered.insert(id)
        let deadline = ContinuousClock.now + .seconds(5)
        while FileManager.default.fileExists(atPath: file.path), ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(50))
        }
        try? await Task.sleep(for: .milliseconds(200))
    }

    private func execute(_ request: BridgeRequest) async throws -> BridgeResponse {
        #if DEBUG
        if request.action.hasPrefix("debug."), ProcessInfo.processInfo.environment["HEKA_STATE_DIRECTORY"] != nil {
            return try await DevelopmentCapture.execute(request, store: store)
        }
        #endif
        if request.action == "list" { return BridgeResponse(ok: true, workspace: store.state) }
        switch request.action {
        case "terminal.send": return try await sendInput(request)
        case "terminal.read": return try await readOutput(request)
        case "terminal.wait": return try await waitForTerminal(request)
        default: break
        }
        guard !store.isReadOnly else { throw WorkspaceError(message: String(localized: "The saved organization is unreadable. Fix it, then use Retry in the app before creating terminals.")) }
        if request.action == "project.add", let path = request.path {
            let project = try store.addProject(URL(fileURLWithPath: path))
            return BridgeResponse(ok: true, projectID: project.id, worktreeID: project.worktrees[0].id, path: project.path)
        }
        if request.action == "terminal.close" { return try await closeTerminal(request) }
        let location = location(of: request.directory)
        if request.action == "worktree.delete" { return try await deleteWorktree(request, currentLocation: location) }
        if request.action.hasPrefix("group.") { return try manageGroup(request, location: location) }
        let request = resolvingContext(of: request, location: location)
        guard let projectID = request.projectID,
              let project = store.projects.first(where: { $0.id == projectID }) else {
            throw WorkspaceError(message: String(localized: "Project not found. Use --project UUID, or run the command from a Heka terminal or from the folder of a project open in Heka."))
        }
        let context: TerminalContext
        switch request.action {
        case "terminal.create":
            let worktreeID = request.worktreeID ?? project.worktrees[0].id
            context = try store.addTerminal(projectID: projectID, worktreeID: worktreeID, command: request.command, select: false)
            if let name = request.name { store.rename(context.terminal.id, to: name) }
        case "worktree.create":
            guard let branch = request.branch else { throw WorkspaceError(message: String(localized: "A branch name is required: --branch feature/my-task.")) }
            if let reference = request.group { _ = try targetGroup(reference, in: project) }
            context = try await store.createWorktree(projectID: projectID, branch: branch, command: request.command, select: false)
            if let name = request.name { store.rename(context.terminal.id, to: name) }
        default:
            throw WorkspaceError(message: String(localized: "Unknown command: \(request.action)"))
        }
        var response = BridgeResponse(ok: true, projectID: context.project.id, worktreeID: context.worktree.id,
                                      terminalID: context.terminal.id, path: context.worktree.path)
        if let reference = request.group {
            response.groupID = place(context.worktree.id, inGroup: reference, of: context.project.id)
            if response.groupID == nil {
                response.message = String(localized: "The worktree was created, but it couldn’t be put in the group “\(reference)”. Use heka group add.")
            }
        }
        return response
    }

    private func deleteWorktree(_ request: BridgeRequest, currentLocation: (projectID: UUID, worktreeID: UUID)?) async throws -> BridgeResponse {
        guard let worktreeID = request.worktreeID,
              let project = project(containing: worktreeID),
              let worktree = project.worktrees.first(where: { $0.id == worktreeID }) else {
            throw WorkspaceError(message: String(localized: "Worktree not found. Get its UUID with heka list."))
        }
        if let projectID = request.projectID, projectID != project.id {
            throw WorkspaceError(message: String(localized: "This worktree doesn’t belong to the specified project."))
        }
        let closesCaller = store.context(for: request.callerTerminalID)?.worktree.id == worktreeID
        if !closesCaller, currentLocation?.worktreeID == worktreeID {
            throw WorkspaceError(message: String(localized: "The current folder belongs to the worktree to delete. Run the command from another folder."))
        }
        let branchRemoval = try request.branchRemoval
        if request.force != true, try await GitService.hasLocalChanges(at: worktree.path) {
            throw WorkspaceError(message: String(localized: "The worktree “\(worktree.displayName)” has uncommitted changes or untracked files. Run again with --force to erase them."))
        }
        let cleanup: BranchCleanup
        do {
            cleanup = try await store.deleteWorktree(projectID: project.id, worktreeID: worktreeID, branch: branchRemoval) {
                guard closesCaller else { return }
                let message = String(localized: "Everything is checked: this terminal closes now, then the worktree is deleted.")
                await replyBeforeClosingCaller(BridgeResponse(ok: true, message: message, projectID: project.id, worktreeID: worktreeID,
                                                              path: worktree.path), to: request.id)
            }
        } catch let error as UnmergedBranchError {
            throw WorkspaceError(message: String(localized: "\(error.localizedDescription) Run again with --force-branch to delete it anyway, or without --delete-branch to keep it."))
        }
        return BridgeResponse(deleting: worktree, of: project.id, cleanup: cleanup)
    }

    private func manageGroup(_ request: BridgeRequest, location: (projectID: UUID, worktreeID: UUID)?) throws -> BridgeResponse {
        let worktreeIDs = request.worktreeIDs ?? []
        let worktreesProject = try worktreeIDs.first.map(existingProject(containing:))
        let projectID = request.projectID ?? worktreesProject?.id ?? location?.projectID
        let targetProject = projectID.flatMap { id in store.projects.first { $0.id == id } }
        if request.action == "group.create" {
            guard let targetProject else {
                throw WorkspaceError(message: String(localized: "Project not found. Use --project UUID, or run the command from a Heka terminal or from the folder of a project open in Heka."))
            }
            try validateGroupable(worktreeIDs, in: targetProject)
            let name = request.name ?? ""
            if let existing = try store.state.worktreeGroup(named: name, in: targetProject) {
                guard store.moveWorktrees(worktreeIDs, to: existing.group.id) || worktreeIDs.isEmpty else { throw groupingFailure }
                return BridgeResponse(ok: true, message: String(localized: "The group “\(existing.group.name)” already existed: it was reused."),
                                      projectID: targetProject.id, groupID: existing.group.id)
            }
            guard let groupID = store.addWorktreeGroup(name, projectID: targetProject.id, moving: worktreeIDs) else { throw groupingFailure }
            return BridgeResponse(ok: true, projectID: targetProject.id, groupID: groupID)
        }
        guard let found = try group(request.group ?? "", in: targetProject) else {
            throw WorkspaceError(message: String(localized: "Worktree group not found. Get its UUID with heka list."))
        }
        try validateGroupable(worktreeIDs, in: found.project)
        switch request.action {
        case "group.add":
            guard store.moveWorktrees(worktreeIDs, to: found.group.id) else { throw groupingFailure }
        case "group.remove":
            let outside = worktreeIDs.filter { id in found.project.worktrees.first { $0.id == id }?.groupID != found.group.id }
            guard outside.isEmpty else { throw WorkspaceError(message: String(localized: "This worktree isn’t in the group “\(found.group.name)”.")) }
            guard store.moveWorktrees(worktreeIDs, to: nil) else { throw groupingFailure }
        case "group.delete":
            store.removeWorktreeGroup(found.group.id)
            return BridgeResponse(ok: true, projectID: found.project.id, groupID: found.group.id, removed: true)
        default:
            throw WorkspaceError(message: String(localized: "Unknown command: \(request.action)"))
        }
        return BridgeResponse(ok: true, projectID: found.project.id, groupID: found.group.id)
    }

    private var groupingFailure: WorkspaceError {
        WorkspaceError(message: String(localized: "The worktrees couldn’t be moved. Check them with heka list."))
    }

    private func targetGroup(_ reference: String, in project: Project) throws -> WorktreeGroup? {
        guard let found = try group(reference, in: project) else { return nil }
        guard found.project.id == project.id else {
            throw WorkspaceError(message: String(localized: "This worktree group belongs to another project."))
        }
        return found.group
    }

    private func place(_ worktreeID: UUID, inGroup reference: String, of projectID: UUID) -> UUID? {
        guard let project = store.projects.first(where: { $0.id == projectID }),
              let existing = try? targetGroup(reference, in: project) else {
            return UUID(uuidString: reference) == nil ? store.addWorktreeGroup(reference, projectID: projectID, moving: [worktreeID]) : nil
        }
        return store.moveWorktrees([worktreeID], to: existing.id) ? existing.id : nil
    }

    private func group(_ reference: String, in project: Project?) throws -> (project: Project, group: WorktreeGroup)? {
        try store.state.worktreeGroup(reference, in: project)
    }

    private func existingProject(containing worktreeID: UUID) throws -> Project {
        guard let project = project(containing: worktreeID) else {
            throw WorkspaceError(message: String(localized: "Worktree not found. Get its UUID with heka list."))
        }
        return project
    }

    private func validateGroupable(_ worktreeIDs: [UUID], in project: Project) throws {
        for id in worktreeIDs {
            guard try existingProject(containing: id).id == project.id,
                  let worktree = project.worktrees.first(where: { $0.id == id }) else {
                throw WorkspaceError(message: String(localized: "This worktree doesn’t belong to the group’s project."))
            }
            guard !worktree.isPrimary else { throw WorkspaceError(message: String(localized: "A project’s main folder can’t be grouped.")) }
        }
    }

    private static func leavesWorkspaceUnchanged(_ action: String) -> Bool {
        ["list", "terminal.send", "terminal.read", "terminal.wait"].contains(action) || action.hasPrefix("debug.")
    }

    private func sendInput(_ request: BridgeRequest) async throws -> BridgeResponse {
        let id = try existingTerminal(request.terminalID)
        guard let context = store.startableContext(for: id) else { throw WorkspaceError(message: String(localized: "This worktree is being deleted.")) }
        let session = store.sessions.start(context)
        if let keys = request.keys {
            try await session.press(keys.compactMap(TerminalKey.init(name:)), from: .remote)
        } else {
            try await session.type(request.text ?? "", submitting: request.pressesEnter == true, from: .remote)
        }
        return await state(of: id)
    }

    private func readOutput(_ request: BridgeRequest) async throws -> BridgeResponse {
        let id = try existingTerminal(request.terminalID)
        var response = await state(of: id)
        let session = store.sessions.session(id)
        guard request.reply == true || request.messages != nil else {
            response.output = session?.recentLines(request.lines ?? TerminalWait.defaultLines) ?? ""
            return response
        }
        guard let session else { throw WorkspaceError(message: String(localized: "This terminal isn’t running.")) }
        let conversation = try await session.conversation()
        if let count = request.messages {
            response.messages = Array(conversation.suffix(count))
        } else {
            response.output = Self.reply(in: conversation)
        }
        return response
    }

    private static func reply(in conversation: [SessionMessage]) -> String {
        let start = conversation.lastIndex { $0.kind == .input }.map { $0 + 1 } ?? conversation.startIndex
        return conversation[start...].filter { $0.kind == .assistant }.map(\.text).joined(separator: "\n\n")
    }

    private func closeTerminal(_ request: BridgeRequest) async throws -> BridgeResponse {
        let id = try existingTerminal(request.terminalID)
        guard store.startableContext(for: id) != nil else { throw WorkspaceError(message: String(localized: "This worktree is being deleted.")) }
        var response = await state(of: id)
        let closesCaller = id == request.callerTerminalID
        if !closesCaller, request.force != true, response.status == AgentStatus.working.identifier {
            throw WorkspaceError(message: String(localized: "The agent in this terminal is working. Wait for it with heka terminal wait, or run again with --force to stop it."))
        }
        response.running = false
        response.removed = true
        if closesCaller { await replyBeforeClosingCaller(response, to: request.id) }
        store.closeTerminal(id)
        return response
    }

    private func waitForTerminal(_ request: BridgeRequest) async throws -> BridgeResponse {
        let id = try existingTerminal(request.terminalID)
        let timeout = request.timeoutSeconds ?? TerminalWait.defaultTimeout
        let idle = request.waitsForExit == true ? nil : request.idleSeconds ?? TerminalWait.defaultIdle
        let start = Date.now
        while let session = store.sessions.session(id), !session.hasExited {
            if let idle, Date.now.timeIntervalSince(max(session.lastOutput, start)) >= idle { break }
            guard Date.now.timeIntervalSince(start) < timeout else {
                var response = await state(of: id)
                response.ok = false
                response.message = idle == nil
                    ? String(localized: "The terminal’s command is still running after \(Int(timeout)) seconds.")
                    : String(localized: "The terminal is still printing output after \(Int(timeout)) seconds.")
                return response
            }
            try await Task.sleep(for: .milliseconds(200))
        }
        return await state(of: id)
    }

    private func existingTerminal(_ id: UUID?) throws -> UUID {
        guard let id, let context = store.context(for: id), !context.isFloating else {
            throw WorkspaceError(message: String(localized: "Terminal not found. Get its UUID with heka list."))
        }
        return id
    }

    private func state(of id: UUID) async -> BridgeResponse {
        await store.sessions.refreshAgents()
        let context = store.context(for: id)
        let session = store.sessions.session(id)
        return BridgeResponse(ok: true, projectID: context?.project.id, worktreeID: context?.worktree.id, terminalID: id,
                              path: context?.worktree.path, running: session.map { !$0.hasExited } ?? false,
                              exitCode: session?.exitCode, agent: session?.agentKind, status: session?.agentStatus?.identifier)
    }

    private static func installLauncher(at url: URL) throws {
        let executable = Bundle.main.executableURL!.path.replacingOccurrences(of: "'", with: "'\\''")
        try "#!/bin/sh\nexec '\(executable)' --cli \"$@\"\n".write(to: url, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
    }

    private func resolvingContext(of request: BridgeRequest, location: (projectID: UUID, worktreeID: UUID)?) -> BridgeRequest {
        guard request.projectID == nil else { return request }
        var request = request
        if let worktreeID = request.worktreeID {
            request.projectID = project(containing: worktreeID)?.id
        } else if let location {
            request.projectID = location.projectID
            request.worktreeID = location.worktreeID
        }
        return request
    }

    private func location(of directory: String?) -> (projectID: UUID, worktreeID: UUID)? {
        directory.flatMap { store.state.location(containing: WorkspacePath.canonical(URL(fileURLWithPath: $0))) }
    }

    private func project(containing worktreeID: UUID) -> Project? {
        store.projects.first { $0.worktrees.contains { $0.id == worktreeID } }
    }
}
