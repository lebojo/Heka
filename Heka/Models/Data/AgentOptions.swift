import Foundation

enum AgentModel: String, CaseIterable, Codable, Identifiable, Sendable {
    case automatic = "default"
    case opus, sonnet, haiku

    var id: String { rawValue }

    init?(reported name: String) {
        let name = name.lowercased()
        guard let model = Self.allCases.first(where: { $0 != .automatic && name.contains($0.rawValue) }) else { return nil }
        self = model
    }

    var title: String {
        switch self {
        case .automatic: String(localized: "Default Model", comment: "Model menu option that keeps the agent's default model")
        case .opus: "Opus"
        case .sonnet: "Sonnet"
        case .haiku: "Haiku"
        }
    }

    var efforts: [AgentEffort] {
        switch self {
        case .automatic, .opus: AgentEffort.allCases
        case .sonnet: [.automatic, .low, .medium, .high, .max]
        case .haiku: []
        }
    }

    var command: AgentCommand { AgentCommand(text: "/model \(rawValue)") }
}

enum AgentEffort: String, CaseIterable, Codable, Identifiable, Sendable {
    case automatic = "auto"
    case low, medium, high, xhigh, max

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic: String(localized: "Default Effort", comment: "Reasoning effort menu option that keeps the agent's default effort")
        case .low: String(localized: "Low", comment: "Reasoning effort level")
        case .medium: String(localized: "Medium", comment: "Reasoning effort level")
        case .high: String(localized: "High", comment: "Reasoning effort level")
        case .xhigh: String(localized: "Extra High", comment: "Reasoning effort level")
        case .max: String(localized: "Max", comment: "Reasoning effort level, the highest one")
        }
    }

    var command: AgentCommand { AgentCommand(text: "/effort \(rawValue)") }
}

struct AgentOptions: Codable, Equatable, Sendable {
    var model = AgentModel.automatic
    var effort = AgentEffort.automatic
}

struct AgentCommand: Equatable, Sendable {
    let text: String

    var input: Data { Data(("\u{15}" + text + "\r").utf8) }
}
