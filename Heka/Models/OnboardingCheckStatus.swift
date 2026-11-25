import SwiftUI

enum OnboardingCheckStatus: Equatable {
    case checking
    case working(LocalizedStringKey)
    case ready(LocalizedStringKey)
    case problem(LocalizedStringKey)
}
