import CoreGraphics
import Foundation

enum SplitAxis: String, Codable, Sendable {
    case horizontal, vertical
}

enum DropEdge: Sendable {
    case leading, trailing, top, bottom

    var axis: SplitAxis {
        switch self {
        case .leading, .trailing: .horizontal
        case .top, .bottom: .vertical
        }
    }

    var insertsBefore: Bool { self == .leading || self == .top }

    init(location: CGPoint, in size: CGSize) {
        let x = size.width > 0 ? min(max(location.x / size.width, 0), 1) : 0.5
        let y = size.height > 0 ? min(max(location.y / size.height, 0), 1) : 0.5
        let horizontal: DropEdge = x < 0.5 ? .leading : .trailing
        let vertical: DropEdge = y < 0.5 ? .top : .bottom
        self = min(x, 1 - x) <= min(y, 1 - y) ? horizontal : vertical
    }
}

indirect enum TerminalLayout: Codable, Equatable, Identifiable, Sendable {
    case terminal(UUID)
    case split(SplitAxis, [TerminalLayout], id: UUID = UUID())

    private enum CodingKeys: String, CodingKey {
        case terminal, split
    }

    private enum TerminalKeys: String, CodingKey {
        case id = "_0"
    }

    private enum SplitKeys: String, CodingKey {
        case axis = "_0", children = "_1", id
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.terminal) {
            let terminal = try container.nestedContainer(keyedBy: TerminalKeys.self, forKey: .terminal)
            self = .terminal(try terminal.decode(UUID.self, forKey: .id))
        } else {
            let split = try container.nestedContainer(keyedBy: SplitKeys.self, forKey: .split)
            self = .split(try split.decode(SplitAxis.self, forKey: .axis), try split.decode([TerminalLayout].self, forKey: .children),
                          id: try split.decodeIfPresent(UUID.self, forKey: .id) ?? UUID())
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .terminal(let id):
            var terminal = container.nestedContainer(keyedBy: TerminalKeys.self, forKey: .terminal)
            try terminal.encode(id, forKey: .id)
        case .split(let axis, let children, let id):
            var split = container.nestedContainer(keyedBy: SplitKeys.self, forKey: .split)
            try split.encode(axis, forKey: .axis)
            try split.encode(children, forKey: .children)
            try split.encode(id, forKey: .id)
        }
    }

    var id: UUID {
        switch self {
        case .terminal(let id), .split(_, _, let id): id
        }
    }

    var firstTerminalID: UUID { terminalIDs.first ?? id }

    var terminalIDs: [UUID] {
        switch self {
        case .terminal(let id): [id]
        case .split(_, let children, _): children.flatMap(\.terminalIDs)
        }
    }

    var isSplit: Bool { terminalIDs.count > 1 }

    var axis: SplitAxis? {
        if case .split(let axis, _, _) = self { axis } else { nil }
    }

    func contains(_ id: UUID) -> Bool { terminalIDs.contains(id) }

    func neighbour(of id: UUID) -> UUID? {
        let ids = terminalIDs
        guard let index = ids.firstIndex(of: id) else { return nil }
        return index > 0 ? ids[index - 1] : ids.dropFirst().first
    }

    func splitting(_ id: UUID, with newID: UUID, axis: SplitAxis) -> TerminalLayout {
        switch self {
        case .terminal(let current):
            return current == id ? .split(axis, [self, .terminal(newID)]) : self
        case .split(let current, var children, let splitID):
            if current == axis, let index = children.firstIndex(of: .terminal(id)) {
                children.insert(.terminal(newID), at: index + 1)
                return .split(current, children, id: splitID)
            }
            return .split(current, children.map { $0.splitting(id, with: newID, axis: axis) }, id: splitID)
        }
    }

    func removing(_ id: UUID) -> TerminalLayout? {
        switch self {
        case .terminal(let current):
            return current == id ? nil : self
        case .split(let axis, let children, let splitID):
            return Self.normalised(axis, children.compactMap { $0.removing(id) }, id: splitID)
        }
    }

    func inserting(_ id: UUID, beside target: UUID, edge: DropEdge) -> TerminalLayout {
        guard id != target, contains(target), !contains(id) else { return self }
        switch self {
        case .terminal:
            return .split(edge.axis, edge.insertsBefore ? [.terminal(id), self] : [self, .terminal(id)])
        case .split(let axis, var children, let splitID):
            if axis == edge.axis, let index = children.firstIndex(of: .terminal(target)) {
                children.insert(.terminal(id), at: edge.insertsBefore ? index : index + 1)
                return .split(axis, children, id: splitID)
            }
            return Self.normalised(axis, children.map { $0.inserting(id, beside: target, edge: edge) }, id: splitID) ?? self
        }
    }

    func moving(_ id: UUID, beside target: UUID, edge: DropEdge) -> TerminalLayout {
        guard id != target, contains(target), let remaining = removing(id) else { return self }
        let moved = remaining.inserting(id, beside: target, edge: edge)
        return moved.hasShape(of: self) ? self : moved
    }

    private func hasShape(of other: TerminalLayout) -> Bool {
        switch (self, other) {
        case (.terminal(let id), .terminal(let otherID)):
            id == otherID
        case (.split(let axis, let children, _), .split(let otherAxis, let otherChildren, _)):
            axis == otherAxis && children.count == otherChildren.count && zip(children, otherChildren).allSatisfy { $0.hasShape(of: $1) }
        default:
            false
        }
    }

    private static func normalised(_ axis: SplitAxis, _ children: [TerminalLayout], id: UUID) -> TerminalLayout? {
        let flattened = children.flatMap { child -> [TerminalLayout] in
            if case .split(axis, let grandchildren, _) = child { grandchildren } else { [child] }
        }
        return flattened.count > 1 ? .split(axis, flattened, id: id) : flattened.first
    }
}
