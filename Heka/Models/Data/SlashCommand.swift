import Foundation

struct SlashCommand: Hashable, Sendable, Identifiable {
    let name: String
    let summary: String
    let argument: String?

    var id: String { name }
    var text: String { "/" + name }

    init(name: String, summary: String, argument: String?) {
        self.name = name
        self.summary = summary
        self.argument = argument
    }

    init(_ name: String, _ summary: LocalizedStringResource, argument: LocalizedStringResource? = nil) {
        self.init(name: name, summary: String(localized: summary), argument: argument.map { String(localized: $0) })
    }
}

extension SessionChatSource {
    var slashCommands: [SlashCommand] {
        switch self {
        case .terminal: []
        case .claude: SlashCommand.claude
        case .codex: SlashCommand.codex
        case .copilot: SlashCommand.copilot
        case .openCode: SlashCommand.openCode
        }
    }
}

private extension SlashCommand {
    static let claude: [SlashCommand] = [
        SlashCommand("add-dir", "Add a working directory", argument: "path"),
        SlashCommand("agents", "Manage subagents"),
        SlashCommand("clear", "Clear the conversation"),
        SlashCommand("compact", "Summarize the conversation", argument: "instructions"),
        SlashCommand("config", "Open the settings"),
        SlashCommand("context", "Show the context usage"),
        SlashCommand("cost", "Show the session cost"),
        SlashCommand("doctor", "Check the installation"),
        SlashCommand("export", "Export the conversation"),
        SlashCommand("help", "Show the help"),
        SlashCommand("hooks", "Manage hooks"),
        SlashCommand("init", "Create an AGENTS.md or CLAUDE.md file"),
        SlashCommand("mcp", "Manage MCP servers"),
        SlashCommand("memory", "Edit the memory files"),
        SlashCommand("model", "Change the model", argument: "model"),
        SlashCommand("permissions", "Manage permissions"),
        SlashCommand("pr-comments", "Show the pull request comments"),
        SlashCommand("resume", "Resume a conversation", argument: "session"),
        SlashCommand("review", "Review the changes"),
        SlashCommand("rewind", "Go back to an earlier point"),
        SlashCommand("security-review", "Review the changes for security issues"),
        SlashCommand("status", "Show the status"),
        SlashCommand("usage", "Show the plan usage")
    ]

    static let codex: [SlashCommand] = [
        SlashCommand("approvals", "Choose what runs without approval"),
        SlashCommand("compact", "Summarize the conversation"),
        SlashCommand("diff", "Show the Git diff"),
        SlashCommand("init", "Create an AGENTS.md file"),
        SlashCommand("mcp", "List MCP tools"),
        SlashCommand("mention", "Mention a file", argument: "file"),
        SlashCommand("model", "Change the model"),
        SlashCommand("new", "Start a new conversation"),
        SlashCommand("review", "Review the changes"),
        SlashCommand("status", "Show the status"),
        SlashCommand("undo", "Undo the last turn")
    ]

    static let copilot: [SlashCommand] = [
        SlashCommand("add-dir", "Add a working directory", argument: "path"),
        SlashCommand("agent", "Choose an agent"),
        SlashCommand("clear", "Clear the conversation"),
        SlashCommand("cwd", "Change the working directory", argument: "path"),
        SlashCommand("help", "Show the help"),
        SlashCommand("mcp", "Manage MCP servers"),
        SlashCommand("model", "Change the model", argument: "model"),
        SlashCommand("session", "Show the session"),
        SlashCommand("share", "Share the conversation"),
        SlashCommand("usage", "Show the usage")
    ]

    static let openCode: [SlashCommand] = [
        SlashCommand("compact", "Summarize the conversation"),
        SlashCommand("details", "Toggle tool details"),
        SlashCommand("export", "Export the conversation"),
        SlashCommand("help", "Show the help"),
        SlashCommand("init", "Create an AGENTS.md file"),
        SlashCommand("models", "Change the model"),
        SlashCommand("new", "Start a new conversation"),
        SlashCommand("redo", "Redo the last undone message"),
        SlashCommand("sessions", "Switch session"),
        SlashCommand("share", "Share the conversation"),
        SlashCommand("undo", "Undo the last message")
    ]
}
