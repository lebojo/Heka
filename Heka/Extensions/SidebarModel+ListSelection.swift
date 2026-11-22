import Foundation

extension SidebarModel where Self: AnyObject {
    var listSelection: UUID? {
        get { selection }
        set {
            #if os(macOS)
            guard let newValue else { return }
            #endif
            selection = newValue
        }
    }
}
