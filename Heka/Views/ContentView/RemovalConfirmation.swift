import SwiftUI

struct RemovalConfirmation: View {
    @Environment(WorkspaceStore.self) private var store
    @Environment(WorkspacePresentation.self) private var presentation

    @State private var prompt: RemovalPrompt?
    @State private var skipsConfirmation = false

    private var removal: Removal? { presentation.removal }

    var body: some View {
        ZStack {
            RemovalConfirmationDialog(prompt: prompt(allowingSkip: true), skipsConfirmation: skipsConfirmation)
                .dialogSuppressionToggle("Don’t ask again", isSuppressed: $skipsConfirmation)
            RemovalConfirmationDialog(prompt: prompt(allowingSkip: false), skipsConfirmation: false)
        }
        .alert(Text(store.unmergedRemoval?.error.reason ?? ""), isPresented: Bindable(store).unmergedRemoval.isPresent, presenting: store.unmergedRemoval) { unmerged in
            Button("Delete Worktree Only", role: .destructive) { store.remove(unmerged.removal) }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("Nothing was removed. You can delete the worktree and keep the branch and its commits in the repository.")
        }
        .task(id: removal) {
            skipsConfirmation = false
            guard let removal else {
                prompt = nil
                return
            }
            await present(removal)
        }
    }

    private func present(_ removal: Removal) async {
        let branch = await store.deletableBranchBeforeDeadline(for: removal)
        guard !Task.isCancelled else { return }
        prompt = RemovalPrompt(removal: removal, deletableBranch: branch)
    }

    private func prompt(allowingSkip: Bool) -> RemovalPrompt? {
        prompt?.removal.allowsSkippingConfirmation == allowingSkip ? prompt : nil
    }
}
