import Foundation

enum OnboardingStep: Int, CaseIterable, Identifiable, Sendable {
    case welcome, concepts, setup, project

    var id: Int { rawValue }

    var previous: OnboardingStep? { OnboardingStep(rawValue: rawValue - 1) }
    var next: OnboardingStep? { OnboardingStep(rawValue: rawValue + 1) }
}

enum OnboardingKey {
    static let completed = "onboardingCompleted"
    static let replayRequested = "onboardingReplayRequested"
}
