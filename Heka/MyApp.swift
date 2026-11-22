import SwiftUI
import AppKit

@main enum HekaEntry {
    static func main() {
        if CommandLine.arguments.dropFirst().first == "--cli" {
            exit(AgentCLI.run(arguments: Array(CommandLine.arguments.dropFirst(2))))
        }
        if CommandLine.arguments.first.map({ URL(fileURLWithPath: $0).lastPathComponent }) == CommandLineInstaller.commandName {
            exit(AgentCLI.run(arguments: Array(CommandLine.arguments.dropFirst())))
        }
        WorkspaceDisk.isolateDebugState()
        AgentUIMigration.run()
        raiseOpenFileLimit()
        HekaApplication.main()
    }

    private static func raiseOpenFileLimit() {
        var limit = rlimit()
        guard getrlimit(RLIMIT_NOFILE, &limit) == 0 else { return }
        let target = min(limit.rlim_max, rlim_t(10_240))
        guard limit.rlim_cur < target else { return }
        limit.rlim_cur = target
        setrlimit(RLIMIT_NOFILE, &limit)
    }
}

@MainActor final class ApplicationDelegate: NSObject, NSApplicationDelegate {
    var store: WorkspaceStore?
    var floating: FloatingTerminalStore?
    var bridge: AgentBridge?
    var closeCommand: CloseTerminalCommand?
    var host: LocalHost?
    var gitActionQueues: GitActionQueues?

    private var finishingTermination = false

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard !finishingTermination else { return .terminateLater }
        guard let store else { return .terminateNow }
        let isRunningGitAction = gitActionQueues?.hasPendingAction == true
        let isChangingWorktrees = !store.busyProjects.isEmpty
        if store.sessions.runningCount > 0 || isRunningGitAction || isChangingWorktrees {
            let alert = NSAlert()
            alert.messageText = String(localized: "Quit Heka?")
            alert.informativeText = quitWarnings(isRunningGitAction: isRunningGitAction, isChangingWorktrees: isChangingWorktrees,
                                                 hasRunningTerminals: store.sessions.runningCount > 0)
            alert.addButton(withTitle: String(localized: "Quit"))
            alert.addButton(withTitle: String(localized: "Cancel"))
            guard alert.runModal() == .alertFirstButtonReturn else { return .terminateCancel }
        }
        guard store.sessions.runningCount > 0 || store.hasUnsavedChanges || isChangingWorktrees else { return .terminateNow }
        finishingTermination = true
        Task { @MainActor in
            await store.waitForGitOperations(upTo: .seconds(30))
            if store.sessions.runningCount > 0 {
                await store.sessions.refreshAgents()
                store.recordAgentSessions()
            }
            do {
                repeat { try await store.flushPersistence() } while store.hasUnsavedChanges
                sender.reply(toApplicationShouldTerminate: true)
            } catch {
                let quits = confirmsQuitWithoutSaving(error)
                finishingTermination = false
                if !quits { store.errorMessage = String(localized: "Quitting was cancelled to keep unsaved changes. \(error.localizedDescription)") }
                sender.reply(toApplicationShouldTerminate: quits)
            }
        }
        return .terminateLater
    }

    private func confirmsQuitWithoutSaving(_ error: Error) -> Bool {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = String(localized: "Your changes couldn’t be saved.")
        alert.informativeText = error.localizedDescription
        alert.addButton(withTitle: String(localized: "Quit Anyway"))
        alert.addButton(withTitle: String(localized: "Cancel"))
        return alert.runModal() == .alertFirstButtonReturn
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        Task { await ComposerImageStore.pruneExpired() }
    }

    func applicationWillTerminate(_ notification: Notification) {
        CommandRunner.terminateAll()
        floating?.persist()
        store?.sessions.stopAll()
        bridge?.stop()
        host?.stop()
    }

    private func quitWarnings(isRunningGitAction: Bool, isChangingWorktrees: Bool, hasRunningTerminals: Bool) -> String {
        let gitAction = isRunningGitAction ? String(localized: "A Git action is still running and will be interrupted.") : nil
        let worktrees = isChangingWorktrees ? String(localized: "A worktree is being created or deleted: Heka waits up to 30 seconds for it to finish.") : nil
        let terminals = hasRunningTerminals ? String(localized: "Terminals and their processes will be stopped. Your project organization will be kept and agent sessions will resume the next time you open Heka.") : nil
        return [gitAction, worktrees, terminals].compactMap { $0 }.joined(separator: " ")
    }
}

struct HekaApplication: App {
    @NSApplicationDelegateAdaptor(ApplicationDelegate.self) private var delegate
    @State private var store: WorkspaceStore
    @State private var floating: FloatingTerminalStore
    @State private var usage = UsageStore(providers: [])
    @State private var settings = SettingsStore()
    @State private var visibility = AppVisibility()
    @State private var host = LocalHost()
    @State private var installedAgents = InstalledAgents()
    @State private var gitActionQueues = GitActionQueues()
    @State private var chatDrafts = ChatDrafts()

    init() {
        let store = WorkspaceStore()
        _store = State(initialValue: store)
        _floating = State(initialValue: FloatingTerminalStore(sessions: store.sessions))
    }

    var body: some Scene {
        Window("Heka", id: "workspace") {
            ContentView(store: store, gitActionQueues: gitActionQueues)
                .modifier(SheetSpaceProvider())
                .modifier(OnboardingPresenter())
                .environment(store)
                .environment(floating)
                .environment(usage)
                .environment(settings)
                .environment(visibility)
                .environment(installedAgents)
                .environment(chatDrafts)
                .task(id: visibility.isVisible) { if visibility.isVisible { await installedAgents.refresh() } }
                .task(id: installedAgents.agents) { await usage.setInstalled(installedAgents.agents) }
                .onAppear {
                    delegate.store = store
                    delegate.floating = floating
                    delegate.host = host
                    delegate.gitActionQueues = gitActionQueues
                    host.configure(store: store, settings: settings, installedAgents: installedAgents)
                    if delegate.closeCommand == nil { delegate.closeCommand = CloseTerminalCommand(store: store, floating: floating) }
                    if delegate.bridge == nil {
                        do { delegate.bridge = try AgentBridge(store: store) }
                        catch { store.errorMessage = error.localizedDescription }
                    }
                    store.restoreSessions()
                }
        }
        .defaultSize(width: Dimension.Window.defaultWidth, height: Dimension.Window.defaultHeight)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Add Project…") { store.chooseProjects() }.keyboardShortcut(.addProject).disabled(!store.canImport)
                Button("Import Folder…") { store.chooseFolder() }.keyboardShortcut(.importFolder).disabled(!store.canImport)
            }
            NewVirtualFolderCommand(isDisabled: !store.canImport)
            FloatingTerminalCommands(floating: floating)
            CommandGroup(replacing: .help) {
                OnboardingReplayButton()
                Button("Agent Commands") {
                    let alert = NSAlert()
                    alert.messageText = String(localized: "Control Heka from a Terminal")
                    alert.informativeText = AgentCLI.help
                    alert.runModal()
                }
            }
        }
        Settings {
            SettingsView()
                .environment(settings)
                .environment(host)
        }
    }
}
