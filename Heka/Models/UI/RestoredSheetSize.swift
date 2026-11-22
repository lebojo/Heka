import Foundation

@MainActor final class RestoredSheetSize {
    private var size: CGSize?

    func size(of kind: PreviewSheetKind, fitting space: CGSize?) -> CGSize {
        if let size { return size }
        let defaults = UserDefaults.standard
        let restored = kind.restoredSize(width: defaults.double(forKey: kind.widthKey), height: defaults.double(forKey: kind.heightKey),
                                         fitting: space)
        size = restored
        return restored
    }
}
