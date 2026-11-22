import Foundation
import UniformTypeIdentifiers

enum ComposerImageStore {
    static let retention: TimeInterval = 24 * 60 * 60

    static var directory: URL {
        URL.cachesDirectory.appending(path: "Heka/PastedImages", directoryHint: .isDirectory)
    }

    @concurrent static func store(png data: Data) async -> URL? {
        guard let file = try? newFile(extension: "png") else { return nil }
        return (try? data.write(to: file, options: .atomic)).map { file }
    }

    @concurrent static func copies(of files: [URL]) async -> [URL] {
        files.compactMap { file in
            guard let copy = try? newFile(extension: file.pathExtension.isEmpty ? "png" : file.pathExtension.lowercased()) else { return nil }
            guard (try? FileManager.default.copyItem(at: file, to: copy)) != nil else { return nil }
            try? FileManager.default.setAttributes([.modificationDate: Date.now], ofItemAtPath: copy.path)
            return copy
        }
    }

    @concurrent static func discard(_ image: URL) async {
        guard owns(image, in: directory) else { return }
        try? FileManager.default.removeItem(at: image)
    }

    @concurrent static func pruneExpired() async {
        prune(directory, before: .now.addingTimeInterval(-retention))
    }

    static func isImage(_ file: URL) -> Bool {
        file.isFileURL && UTType(filenameExtension: file.pathExtension)?.conforms(to: .image) == true
    }

    static func owns(_ file: URL, in directory: URL) -> Bool {
        file.isFileURL && file.deletingLastPathComponent().standardizedFileURL == directory.standardizedFileURL
    }

    static func prune(_ directory: URL, before limit: Date) {
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
        for file in files where modificationDate(of: file).map({ $0 < limit }) == true {
            try? FileManager.default.removeItem(at: file)
        }
    }

    private static func modificationDate(of file: URL) -> Date? {
        try? file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }

    private static func newFile(extension pathExtension: String) throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: UUID().uuidString).appendingPathExtension(pathExtension)
    }
}
