import SwiftUI

struct OnboardingReplayButton: View {
    @AppStorage(OnboardingKey.replayRequested) private var isReplayRequested = false

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Show Welcome Tour") {
            openWindow(id: "workspace")
            isReplayRequested = true
        }
    }
}
