import SwiftUI

struct OnboardingPresenter: ViewModifier {
    @AppStorage(OnboardingKey.completed) private var isCompleted = false
    @AppStorage(OnboardingKey.completedRelease) private var completedRelease = ""
    @AppStorage(OnboardingKey.replayRequested) private var isReplayRequested = false

    @Environment(WorkspaceStore.self) private var store

    @State private var presentedStep: OnboardingStep?

    func body(content: Content) -> some View {
        content
            .sheet(item: $presentedStep, onDismiss: markCompleted) { step in
                OnboardingView(step: step)
            }
            .onAppear(perform: presentOnLaunch)
            .onChange(of: isReplayRequested, initial: true) { presentReplay() }
    }

    private func presentOnLaunch() {
        guard presentedStep == nil else { return }
        let launch = OnboardingLaunch(isCompleted: isCompleted, completedRelease: completedRelease,
                                      currentRelease: OnboardingLaunch.currentRelease,
                                      isWorkspaceEmpty: store.projects.isEmpty && store.folders.isEmpty)
        switch launch {
        case .none: break
        case .complete: markCompleted()
        case .present(let step): presentedStep = step
        }
    }

    private func presentReplay() {
        guard isReplayRequested else { return }
        isReplayRequested = false
        presentedStep = .welcome
    }

    private func markCompleted() {
        isCompleted = true
        completedRelease = OnboardingLaunch.currentRelease
    }
}
