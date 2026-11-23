import CoreTransferable
import Foundation

enum SidebarDropItem: Transferable, Sendable {
    case folder(URL)
    case sidebarItem(String)

    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(importing: { (url: URL) in SidebarDropItem.folder(url) })
        ProxyRepresentation(importing: { (value: String) in SidebarDropItem.sidebarItem(value) })
    }

    var folderURL: URL? {
        guard case .folder(let url) = self else { return nil }
        return url
    }

    var sidebarItemID: UUID? {
        guard case .sidebarItem(let value) = self else { return nil }
        return UUID(uuidString: value)
    }
}
