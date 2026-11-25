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
        SlashCommand("advisor", "Consult a stronger model at key moments"),
        SlashCommand("background", "Send the session to the background"),
        SlashCommand("branch", "Branch the conversation from here", argument: "name"),
        SlashCommand("btw", "Ask a side question", argument: "question"),
        SlashCommand("cd", "Change the working directory", argument: "path"),
        SlashCommand("clear", "Clear the conversation"),
        SlashCommand("code-review", "Review the changes for bugs"),
        SlashCommand("compact", "Summarize the conversation", argument: "instructions"),
        SlashCommand("config", "Open the settings"),
        SlashCommand("context", "Show the context usage"),
        SlashCommand("copy", "Copy the last response"),
        SlashCommand("diff", "Show the uncommitted changes"),
        SlashCommand("doctor", "Check the installation"),
        SlashCommand("effort", "Set the effort level"),
        SlashCommand("export", "Export the conversation"),
        SlashCommand("fast", "Toggle fast mode"),
        SlashCommand("feedback", "Send feedback"),
        SlashCommand("fork", "Start a background agent with the conversation", argument: "task"),
        SlashCommand("goal", "Set a goal to reach before stopping", argument: "condition"),
        SlashCommand("help", "Show the help"),
        SlashCommand("hooks", "Manage hooks"),
        SlashCommand("ide", "Manage IDE integrations"),
        SlashCommand("init", "Create a CLAUDE.md file"),
        SlashCommand("insights", "Analyze your sessions"),
        SlashCommand("loop", "Run a prompt on an interval", argument: "interval"),
        SlashCommand("mcp", "Manage MCP servers"),
        SlashCommand("memory", "Edit the memory files"),
        SlashCommand("model", "Change the model", argument: "model"),
        SlashCommand("output-style", "Change the output style"),
        SlashCommand("permissions", "Manage permissions"),
        SlashCommand("plan", "Turn on plan mode"),
        SlashCommand("plugin", "Manage plugins"),
        SlashCommand("recap", "Recap the conversation"),
        SlashCommand("release-notes", "Show the release notes"),
        SlashCommand("reload-plugins", "Reload the plugins"),
        SlashCommand("reload-skills", "Reload the skills"),
        SlashCommand("rename", "Rename the conversation", argument: "name"),
        SlashCommand("resume", "Resume a conversation", argument: "session"),
        SlashCommand("rewind", "Go back to an earlier point"),
        SlashCommand("schedule", "Schedule remote agents"),
        SlashCommand("security-review", "Review the changes for security issues"),
        SlashCommand("simplify", "Simplify the changed code"),
        SlashCommand("skills", "List the skills"),
        SlashCommand("status", "Show the status"),
        SlashCommand("subtask", "Send a subagent with the full context", argument: "task"),
        SlashCommand("tasks", "Show the background tasks"),
        SlashCommand("usage", "Show the cost and plan usage")
    ]

    static let codex: [SlashCommand] = [
        SlashCommand("agents", "Manage the agents"),
        SlashCommand("cd", "Change the working directory", argument: "path"),
        SlashCommand("clear", "Clear the conversation"),
        SlashCommand("compact", "Summarize the conversation"),
        SlashCommand("config", "Open the settings"),
        SlashCommand("copy", "Copy the last response"),
        SlashCommand("diff", "Show the Git diff"),
        SlashCommand("experimental", "Toggle experimental features"),
        SlashCommand("export", "Export the conversation"),
        SlashCommand("fork", "Fork the conversation"),
        SlashCommand("hooks", "Manage hooks"),
        SlashCommand("import", "Import the Claude Code setup"),
        SlashCommand("init", "Create an AGENTS.md file"),
        SlashCommand("mcp", "List MCP tools"),
        SlashCommand("memories", "Configure the memories"),
        SlashCommand("mention", "Mention a file", argument: "file"),
        SlashCommand("model", "Change the model", argument: "model"),
        SlashCommand("new", "Start a new conversation"),
        SlashCommand("permissions", "Choose what the agent can do"),
        SlashCommand("presets", "Run or save a reusable prompt"),
        SlashCommand("ps", "List the background terminals"),
        SlashCommand("recap", "Recap the conversation"),
        SlashCommand("rename", "Rename the conversation", argument: "name"),
        SlashCommand("resume", "Resume a conversation"),
        SlashCommand("review", "Review the changes"),
        SlashCommand("side", "Ask a side question", argument: "question"),
        SlashCommand("skills", "Use a skill"),
        SlashCommand("status", "Show the status"),
        SlashCommand("stop", "Stop the background terminals"),
        SlashCommand("subagents", "Switch between subagents")
    ]

    static let copilot: [SlashCommand] = [
        SlashCommand("add-dir", "Add a working directory", argument: "path"),
        SlashCommand("agent", "Choose an agent"),
        SlashCommand("allow-all", "Allow all permissions"),
        SlashCommand("ask", "Ask a side question", argument: "question"),
        SlashCommand("autopilot", "Toggle autopilot mode"),
        SlashCommand("clear", "Clear the conversation"),
        SlashCommand("compact", "Summarize the conversation", argument: "instructions"),
        SlashCommand("config", "Open the settings"),
        SlashCommand("context", "Show the context usage"),
        SlashCommand("copy", "Copy the last response"),
        SlashCommand("cwd", "Change the working directory", argument: "path"),
        SlashCommand("delegate", "Hand the session to GitHub to open a pull request"),
        SlashCommand("diff", "Show the uncommitted changes"),
        SlashCommand("feedback", "Send feedback"),
        SlashCommand("fleet", "Run subagents in parallel"),
        SlashCommand("fork", "Fork the conversation"),
        SlashCommand("help", "Show the help"),
        SlashCommand("ide", "Manage IDE integrations"),
        SlashCommand("init", "Create an instructions file"),
        SlashCommand("instructions", "Manage the instruction files"),
        SlashCommand("list-dirs", "List the allowed directories"),
        SlashCommand("mcp", "Manage MCP servers"),
        SlashCommand("memory", "Manage the memory"),
        SlashCommand("model", "Change the model", argument: "model"),
        SlashCommand("new", "Start a new conversation"),
        SlashCommand("permissions", "Manage permissions"),
        SlashCommand("plan", "Plan before coding"),
        SlashCommand("plugin", "Manage plugins"),
        SlashCommand("pr", "Manage the pull request"),
        SlashCommand("rename", "Rename the conversation", argument: "name"),
        SlashCommand("research", "Research a topic in depth"),
        SlashCommand("resume", "Resume a conversation", argument: "session"),
        SlashCommand("review", "Review the changes"),
        SlashCommand("rewind", "Go back to an earlier point"),
        SlashCommand("security-review", "Review the changes for security issues"),
        SlashCommand("session", "Show the session"),
        SlashCommand("share", "Share the conversation"),
        SlashCommand("skills", "Manage skills"),
        SlashCommand("tasks", "Show the background tasks"),
        SlashCommand("usage", "Show the usage")
    ]

    static let openCode: [SlashCommand] = [
        SlashCommand("agents", "Choose an agent"),
        SlashCommand("compact", "Summarize the conversation"),
        SlashCommand("connect", "Connect a provider"),
        SlashCommand("copy", "Copy the conversation"),
        SlashCommand("diff", "Show the uncommitted changes"),
        SlashCommand("editor", "Edit the message in an editor"),
        SlashCommand("export", "Export the conversation"),
        SlashCommand("fork", "Fork the conversation"),
        SlashCommand("help", "Show the help"),
        SlashCommand("init", "Create an AGENTS.md file"),
        SlashCommand("mcps", "Toggle MCP servers"),
        SlashCommand("models", "Change the model"),
        SlashCommand("new", "Start a new conversation"),
        SlashCommand("redo", "Redo the last undone message"),
        SlashCommand("rename", "Rename the conversation"),
        SlashCommand("review", "Review the changes"),
        SlashCommand("sessions", "Switch session"),
        SlashCommand("skills", "Use a skill"),
        SlashCommand("status", "Show the status"),
        SlashCommand("thinking", "Toggle the reasoning"),
        SlashCommand("timeline", "Jump to a message"),
        SlashCommand("undo", "Undo the last message"),
        SlashCommand("variants", "Change the model variant")
    ]
}
