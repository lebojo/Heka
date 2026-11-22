#if os(macOS)
import SwiftUI

struct RemovalConfirmationDialog: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(WorkspaceStore.self) private var store
    @Environment(WorkspacePresentation.self) private var presentation

    let prompt: RemovalPrompt?
    let skipsConfirmation: Bool

    private var branch: String? { prompt?.deletableBranch }

    var body: some View {
        Color.clear.confirmationDialog(prompt?.removal.title ?? "", isPresented: Bindable(presentation)[presenting: prompt], titleVisibility: .visible) {
            Button(role: .destructive) { confirm(.keep) } label: { Text(prompt?.removal.confirmation(deletableBranch: branch) ?? "") }
            if branch != nil {
                Button("Delete Worktree and Branch", role: .destructive) { confirm(.merged(confirmed: branch)) }
            }
        } message: { Text(prompt?.removal.message(deletableBranch: branch) ?? "") }
    }

    private func confirm(_ branchRemoval: BranchRemoval) {
        guard let removal = presentation.removal else { return }
        if skipsConfirmation { settings.confirmations.skip(removal) }
        store.remove(removal, branch: branchRemoval)
        presentation.removal = nil
    }
}
#endif
