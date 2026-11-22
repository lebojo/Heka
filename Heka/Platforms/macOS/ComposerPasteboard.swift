#if os(macOS)
import AppKit

enum ComposerPasteboard {
    enum Content: Sendable {
        case files([URL])
        case bitmap(Data)
    }

    @MainActor static func content(of pasteboard: NSPasteboard) -> Content? {
        let files = (pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? [])
            .filter(ComposerImageStore.isImage)
        if !files.isEmpty { return .files(files) }
        guard pasteboard.string(forType: .string) == nil, let tiff = NSImage(pasteboard: pasteboard)?.tiffRepresentation else { return nil }
        return .bitmap(tiff)
    }

    @concurrent static func store(_ content: Content) async -> [URL] {
        switch content {
        case .files(let files):
            return await ComposerImageStore.copies(of: files)
        case .bitmap(let tiff):
            guard let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]),
                  let file = await ComposerImageStore.store(png: png) else { return [] }
            return [file]
        }
    }
}
#endif
