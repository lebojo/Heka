import SwiftUI

struct RemovalButton: View {
    @Environment(\.removalConfirmations) private var confirmations
    @Environment(SidebarStore.self) private var store
    @Environment(WorkspacePresentation.self) private var presentation

    let removal: Removal
    let placement: Placement

    private var requiresConfirmation: Bool { confirmations.requires(removal) }
    private var title: String {
        switch placement {
        case .menu: requiresConfirmation ? removal.actionTitle + "…" : removal.actionTitle
        case .swipe: removal.shortTitle
        }
    }
    private var role: ButtonRole? {
        switch placement {
        case .menu: .destructive
        case .swipe: nil
        }
    }

    var body: some View {
        Button(title, systemImage: removal.systemImage, role: role) { request() }
            .tint(Palette.danger)
            .disabled(store.isReadOnly || store.isBusy(removal))
    }

    private func request() {
        if requiresConfirmation { presentation.removal = removal }
        else { store.remove(removal, branch: .keep) }
    }

    enum Placement {
        case menu, swipe
    }
}
