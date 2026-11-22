import SwiftUI

enum OnboardingCheckStatus: Equatable {
    case checking
    case ready(LocalizedStringKey)
    case problem(LocalizedStringKey)
}
