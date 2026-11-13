import CoreGraphics

enum PreviewSheetKind: String, Sendable {
    case text
    case diff
    case floatingTerminal

    var widthKey: String { "sheetSize.\(rawValue).width" }
    var heightKey: String { "sheetSize.\(rawValue).height" }

    var defaultSize: CGSize {
        switch self {
        case .text: CGSize(width: Dimension.PreviewSheet.idealWidth, height: Dimension.PreviewSheet.idealHeight)
        case .diff: CGSize(width: Dimension.DiffSheet.idealWidth, height: Dimension.DiffSheet.idealHeight)
        case .floatingTerminal: CGSize(width: Dimension.FloatingTerminal.idealWidth, height: Dimension.FloatingTerminal.idealHeight)
        }
    }

    static let minimumSize = CGSize(width: Dimension.PreviewSheet.minWidth, height: Dimension.PreviewSheet.minHeight)
    static let maximumSavedLength: CGFloat = 20_000

    func restoredSize(width: Double, height: Double, fitting maximum: CGSize?) -> CGSize {
        let saved = Self.isValid(width) && Self.isValid(height) ? CGSize(width: width, height: height) : defaultSize
        guard let maximum else { return saved }
        return CGSize(width: Self.clamp(saved.width, minimum: Self.minimumSize.width, maximum: maximum.width),
                      height: Self.clamp(saved.height, minimum: Self.minimumSize.height, maximum: maximum.height))
    }

    static func isValid(_ length: Double) -> Bool {
        length.isFinite && length > 0 && length <= maximumSavedLength
    }

    private static func clamp(_ value: CGFloat, minimum: CGFloat, maximum: CGFloat) -> CGFloat {
        min(max(value, minimum), max(minimum, maximum))
    }
}
