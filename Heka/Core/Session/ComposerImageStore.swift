import Foundation
import UniformTypeIdentifiers

enum ComposerImageStore {
    static var directory: URL {
        URL.cachesDirectory.appending(path: "Heka/PastedImages", directoryHint: .isDirectory)
    }

    static func store(png data: Data) throws -> URL {
        try write(data, extension: "png")
    }

    static func store(copyOf file: URL) throws -> URL {
        try write(Data(contentsOf: file), extension: file.pathExtension.isEmpty ? "png" : file.pathExtension.lowercased())
    }

    static func isImage(_ file: URL) -> Bool {
        UTType(filenameExtension: file.pathExtension)?.conforms(to: .image) ?? false
    }

    private static func write(_ data: Data, extension pathExtension: String) throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appending(path: UUID().uuidString).appendingPathExtension(pathExtension)
        try data.write(to: file, options: .atomic)
        return file
    }
}
