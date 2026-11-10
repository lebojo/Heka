import SwiftUI

struct MobileRemovalButton: View {
    @Environment(MobileWorkspaceStore.self) private var store
    @Environment(WorkspacePresentation.self) private var presentation

    let removal: Removal
    let placement: Placement

    var body: some View {
        Button(placement.title(of: removal), systemImage: removal.systemImage, role: placement.role) { presentation.removal = removal }
            .tint(Palette.danger)
            .disabled(store.isReadOnly || store.isBusy(removal))
    }

    enum Placement {
        case menu, swipe

        var role: ButtonRole? {
            switch self {
            case .menu: .destructive
            case .swipe: nil
            }
        }

        func title(of removal: Removal) -> String {
            switch self {
            case .menu: removal.actionTitle + "…"
            case .swipe: removal.shortTitle
            }
        }
    }
}
