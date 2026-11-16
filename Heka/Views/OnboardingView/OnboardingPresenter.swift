import SwiftUI

struct OnboardingPresenter: ViewModifier {
    @AppStorage(OnboardingKey.completed) private var isCompleted = false
    @AppStorage(OnboardingKey.replayRequested) private var isReplayRequested = false

    @Environment(WorkspaceStore.self) private var store

    @State private var isPresented = false

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented, onDismiss: { isCompleted = true }) {
                OnboardingView()
            }
            .onAppear(perform: presentOnFirstLaunch)
            .onChange(of: isReplayRequested, initial: true) { presentReplay() }
    }

    private func presentOnFirstLaunch() {
        guard !isCompleted else { return }
        if store.projects.isEmpty && store.folders.isEmpty {
            isPresented = true
        } else {
            isCompleted = true
        }
    }

    private func presentReplay() {
        guard isReplayRequested else { return }
        isReplayRequested = false
        isPresented = true
    }
}
