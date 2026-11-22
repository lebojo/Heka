import Foundation

enum TerminalLink: Equatable, Sendable {
    case web(URL)
    case file(URL)

    private static let launcherExtensions: Set<String> = ["app", "command", "tool", "terminal", "fileloc", "inetloc", "webloc"]

    var url: URL {
        switch self {
        case .web(let url), .file(let url): url
        }
    }

    init?(_ link: String, fileManager: FileManager = .default) {
        let url = URL(string: link)
        switch url?.scheme?.lowercased() {
        case "http", "https":
            guard let url, url.host?.isEmpty == false else { return nil }
            self = .web(url)
        case "file":
            guard let path = url?.path, let file = Self.openableFile(at: path, fileManager: fileManager) else { return nil }
            self = .file(file)
        default:
            guard let file = Self.openableFile(at: Self.localPath(link, fileManager: fileManager), fileManager: fileManager) else { return nil }
            self = .file(file)
        }
    }

    private static func localPath(_ link: String, fileManager: FileManager) -> String {
        let path = NSString(string: link).expandingTildeInPath
        guard !fileManager.fileExists(atPath: path),
              let location = path.range(of: #":[0-9]+(?::[0-9]+)?$"#, options: .regularExpression) else { return path }
        return String(path[..<location.lowerBound])
    }

    private static func openableFile(at path: String, fileManager: FileManager) -> URL? {
        var isDirectory: ObjCBool = false
        guard path.hasPrefix("/"), fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else { return nil }
        let url = URL(fileURLWithPath: path)
        let values = try? url.resourceValues(forKeys: [.isPackageKey, .isApplicationKey])
        guard values?.isPackage != true, values?.isApplication != true,
              !launcherExtensions.contains(url.pathExtension.lowercased()),
              isDirectory.boolValue || !fileManager.isExecutableFile(atPath: path) else { return nil }
        return url
    }
}
