import SwiftUI
import AppKit

struct ComposerImagePaste: ViewModifier {
    @State private var monitor: Any?

    let isEnabled: Bool
    let add: ([URL]) -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: isEnabled, initial: true) { updateMonitor() }
            .onDisappear(perform: removeMonitor)
    }

    private func updateMonitor() {
        removeMonitor()
        guard isEnabled else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command,
                  event.charactersIgnoringModifiers == "v" else { return event }
            let images = Self.pastedImages(from: .general)
            guard !images.isEmpty else { return event }
            add(images)
            return nil
        }
    }

    private func removeMonitor() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }

    static func pastedImages(from pasteboard: NSPasteboard) -> [URL] {
        let files = (pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? [])
            .filter(ComposerImageStore.isImage)
        if !files.isEmpty { return files.compactMap { try? ComposerImageStore.store(copyOf: $0) } }
        guard pasteboard.string(forType: .string) == nil,
              let image = NSImage(pasteboard: pasteboard),
              let tiff = image.tiffRepresentation,
              let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]),
              let file = try? ComposerImageStore.store(png: png) else { return [] }
        return [file]
    }
}

extension View {
    func pastesImages(isEnabled: Bool, add: @escaping ([URL]) -> Void) -> some View {
        modifier(ComposerImagePaste(isEnabled: isEnabled, add: add))
            .dropDestination(for: URL.self) { urls, _ in
                let images = urls.filter(ComposerImageStore.isImage).compactMap { try? ComposerImageStore.store(copyOf: $0) }
                guard isEnabled, !images.isEmpty else { return false }
                add(images)
                return true
            }
    }
}
