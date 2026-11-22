import Foundation

infix operator ≈: ComparisonPrecedence

func ≈ (lhs: TerminalLayout?, rhs: TerminalLayout?) -> Bool {
    lhs?.shape == rhs?.shape
}

extension TerminalLayout {
    var shape: String {
        switch self {
        case .terminal(let id): id.uuidString
        case .split(let axis, let children, _): "\(axis.rawValue)(\(children.map(\.shape).joined(separator: ",")))"
        }
    }
}
