import Foundation

enum AgentModel: String, CaseIterable, Codable, Identifiable, Sendable {
    case automatic = "default"
    case opus, sonnet, haiku, fable, mythos

    var id: String { rawValue }

    init(reported name: String) {
        let name = name.lowercased()
        self = Self.allCases.first { $0 != .automatic && name.contains($0.rawValue) } ?? .automatic
    }

    var title: String {
        switch self {
        case .automatic: String(localized: "Default Model", comment: "Model menu option that keeps the agent's default model")
        case .opus: "Opus"
        case .sonnet: "Sonnet"
        case .haiku: "Haiku"
        case .fable: "Fable"
        case .mythos: "Mythos"
        }
    }

    var efforts: [AgentEffort] {
        switch self {
        case .automatic, .opus, .fable, .mythos: AgentEffort.allCases
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

    func applied(within available: [AgentEffort]) -> AgentEffort {
        guard !available.contains(self) else { return self }
        return available.last { $0 != .automatic && $0 < self } ?? .automatic
    }
}

extension AgentEffort: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        allCases.firstIndex(of: lhs)! < allCases.firstIndex(of: rhs)!
    }
}

struct AgentOptions: Codable, Equatable, Sendable {
    var model = AgentModel.automatic
    var effort = AgentEffort.automatic

    func switching(to model: AgentModel, efforts: [AgentEffort]) -> AgentOptions {
        AgentOptions(model: model, effort: effort.applied(within: efforts))
    }
}

struct AgentOptionsReport: Equatable, Sendable {
    var model: AgentModel?
    var effort: AgentEffort?
    var modelReportedOffset: UInt64?

    init(model: AgentModel? = nil, effort: AgentEffort? = nil, modelReportedOffset: UInt64? = nil) {
        self.model = model
        self.effort = effort
        self.modelReportedOffset = modelReportedOffset
    }

    init(launchArguments arguments: [String]) {
        model = Self.value(of: "--model", in: arguments).map { $0 == "default" ? .automatic : AgentModel(reported: $0) }
        effort = Self.value(of: "--effort", in: arguments).flatMap(AgentEffort.init(rawValue:))
    }

    private static func value(of option: String, in arguments: [String]) -> String? {
        let options = arguments.prefix { $0 != "--" }
        var value: String?
        for (index, argument) in zip(options.indices, options) {
            if argument == option, index + 1 < options.endIndex, !options[index + 1].hasPrefix("-") { value = options[index + 1].lowercased() }
            if argument.hasPrefix(option + "=") { value = argument.dropFirst(option.count + 1).lowercased() }
        }
        return value
    }

    func resolved(defaults: AgentOptionsReport) -> AgentOptions {
        let model = model ?? defaults.model ?? .automatic
        let effort = effort ?? defaults.effort ?? .automatic
        return AgentOptions(model: model, effort: effort.applied(within: model.efforts))
    }

    func filling(_ fallback: AgentOptionsReport) -> AgentOptionsReport {
        AgentOptionsReport(model: model ?? fallback.model, effort: effort ?? fallback.effort,
                           modelReportedOffset: model == nil ? fallback.modelReportedOffset : modelReportedOffset)
    }

    func launched(withRecordsFrom boundary: UInt64, options launch: AgentOptionsReport) -> AgentOptionsReport {
        guard let launchModel = launch.model else { return self }
        if let modelReportedOffset, modelReportedOffset >= boundary { return self }
        return AgentOptionsReport(model: launchModel, effort: effort)
    }
}

struct AgentCommand: Equatable, Sendable {
    let text: String

    var input: Data { Data(("\u{15}" + text + "\r").utf8) }
}
