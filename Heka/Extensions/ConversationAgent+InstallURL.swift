import Foundation

extension ConversationAgent {
    var installURL: URL {
        switch self {
        case .claude: URL(string: "https://docs.anthropic.com/en/docs/claude-code/overview")!
        case .codex: URL(string: "https://github.com/openai/codex")!
        case .copilot: URL(string: "https://github.com/github/copilot-cli")!
        case .openCode: URL(string: "https://opencode.ai")!
        }
    }
}
