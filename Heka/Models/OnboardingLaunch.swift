import Foundation

enum OnboardingLaunch: Equatable, Sendable {
    case none
    case complete
    case present(OnboardingStep)

    init(isCompleted: Bool, completedRelease: String, currentRelease: String, isWorkspaceEmpty: Bool) {
        if !isCompleted {
            self = isWorkspaceEmpty ? .present(.welcome) : .complete
        } else if !currentRelease.isEmpty && completedRelease != currentRelease {
            self = .present(.setup)
        } else {
            self = .none
        }
    }

    static var currentRelease: String {
        release(of: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")
    }

    static func release(of version: String) -> String {
        let components = version.split(separator: "-").first.map { $0.split(separator: ".").map(String.init) } ?? []
        guard let major = components.first.flatMap(Int.init) else { return "" }
        let minor = components.dropFirst().first.flatMap(Int.init) ?? 0
        return "\(major).\(minor)"
    }
}
