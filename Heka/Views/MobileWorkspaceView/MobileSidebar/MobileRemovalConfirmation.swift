import SwiftUI

struct MobileRemovalConfirmation: ViewModifier {
    @Environment(MobileWorkspaceStore.self) private var store
    @Environment(WorkspacePresentation.self) private var presentation

    @State private var prompt: Prompt?

    func body(content: Content) -> some View {
        content
            .confirmationDialog(prompt?.removal.title ?? "", isPresented: $prompt.isPresent, titleVisibility: .visible, presenting: prompt) { prompt in
                Button(role: .destructive) { confirm(prompt.removal, .keep) } label: { Text(prompt.removal.confirmation(deletableBranch: prompt.deletableBranch)) }
                if let branch = prompt.deletableBranch {
                    Button("Delete Worktree and Branch", role: .destructive) { confirm(prompt.removal, .merged(confirmed: branch)) }
                }
                Button("Cancel", role: .cancel) {}
            } message: { prompt in
                Text(prompt.removal.message(deletableBranch: prompt.deletableBranch))
            }
            .onChange(of: prompt) { dismissed, shown in
                guard shown == nil, let dismissed, presentation.removal == dismissed.removal else { return }
                presentation.removal = nil
            }
            .task(id: presentation.removal) {
                prompt = nil
                guard let removal = presentation.removal else { return }
                let branch = await store.deletableBranchBeforeDeadline(for: removal)
                guard !Task.isCancelled else { return }
                prompt = Prompt(removal: removal, deletableBranch: branch)
            }
    }

    private func confirm(_ removal: Removal, _ branch: BranchRemoval) {
        presentation.removal = nil
        store.perform { try await store.performRemoval(removal, branch: branch) }
    }

    private struct Prompt: Equatable {
        let removal: Removal
        let deletableBranch: String?
    }
}
