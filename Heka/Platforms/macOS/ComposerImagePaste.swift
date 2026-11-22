import SwiftUI
import AppKit

struct ComposerImagePaste: NSViewRepresentable {
    let isEnabled: Bool
    let add: @MainActor ([URL]) -> Void

    func makeNSView(context: Context) -> ComposerPasteView {
        ComposerPasteView()
    }

    func updateNSView(_ view: ComposerPasteView, context: Context) {
        view.add = add
        view.isEnabled = isEnabled
    }

    static func dismantleNSView(_ view: ComposerPasteView, coordinator: ()) {
        view.isEnabled = false
    }
}

extension View {
    func pastesImages(isEnabled: Bool, isFocused: Bool, add: @escaping @MainActor ([URL]) -> Void) -> some View {
        background(ComposerImagePaste(isEnabled: isEnabled && isFocused, add: add))
            .dropDestination(for: URL.self) { urls, _ in
                let images = urls.filter(ComposerImageStore.isImage)
                guard isEnabled, !images.isEmpty else { return false }
                Task { @MainActor in add(await ComposerImageStore.copies(of: images)) }
                return true
            }
    }
}
