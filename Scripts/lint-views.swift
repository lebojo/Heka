import Foundation

enum Section: Int, Comparable {
    case appStorage
    case environment
    case state
    case stateObject
    case focusState
    case binding
    case observed
    case stored
    case body
    case trailing

    static func < (lhs: Section, rhs: Section) -> Bool { lhs.rawValue < rhs.rawValue }

    var title: String {
        switch self {
        case .appStorage: "@AppStorage / @SceneStorage"
        case .environment: "@Environment / @EnvironmentObject"
        case .state: "@State"
        case .stateObject: "@StateObject"
        case .focusState: "@FocusState"
        case .binding: "@Binding"
        case .observed: "@ObservedObject / @ObservedRealmObject / @ObservedResults / @Bindable"
        case .stored: "let / private var { }"
        case .body: "var body"
        case .trailing: "func / init / nested type"
        }
    }
}

enum Wrapper: String, CaseIterable {
    case appStorage = "AppStorage"
    case sceneStorage = "SceneStorage"
    case environment = "Environment"
    case environmentObject = "EnvironmentObject"
    case state = "State"
    case stateObject = "StateObject"
    case focusState = "FocusState"
    case binding = "Binding"
    case observedObject = "ObservedObject"
    case observedRealmObject = "ObservedRealmObject"
    case observedResults = "ObservedResults"
    case bindable = "Bindable"

    var section: Section {
        switch self {
        case .appStorage, .sceneStorage: .appStorage
        case .environment, .environmentObject: .environment
        case .state: .state
        case .stateObject: .stateObject
        case .focusState: .focusState
        case .binding: .binding
        case .observedObject, .observedRealmObject, .observedResults, .bindable: .observed
        }
    }

    var requiresPrivate: Bool {
        switch self {
        case .binding, .observedObject, .observedRealmObject, .bindable: false
        default: true
        }
    }
}

struct Member {
    var lines: [String]
    let firstLine: Int
    let lastLine: Int
    let blankBefore: Bool
    let extraBlankLines: Bool
    let section: Section
    let missingPrivate: Bool
    let isDirective: Bool
    let name: String
}

struct ViewDeclaration {
    let name: String
    let kind: String
    let headerLine: Int
    let closingLine: Int
    let members: [Member]
}

struct Violation {
    let file: String
    let line: Int
    let message: String
}

struct SourceScan {
    let depths: [Int]
    let commentLines: [Int]
}

struct SourceScanner {
    let lines: [String]

    func scan() -> SourceScan {
        var depths: [Int] = []
        var commentLines: [Int] = []
        var depth = 0
        var inBlockComment = 0
        var stringDelimiter: String?
        var interpolationStack: [(delimiter: String, parentheses: Int)] = []
        for (lineIndex, line) in lines.enumerated() {
            let isInsideLiteral = stringDelimiter != nil || inBlockComment > 0 || !interpolationStack.isEmpty
            depths.append(depth + (isInsideLiteral ? 1 : 0))
            let chars = Array(line)
            var index = 0
            while index < chars.count {
                let char = chars[index]
                let next = index + 1 < chars.count ? chars[index + 1] : nil
                if inBlockComment > 0 {
                    if char == "*" && next == "/" { inBlockComment -= 1; index += 2; continue }
                    if char == "/" && next == "*" { inBlockComment += 1; index += 2; continue }
                    index += 1
                    continue
                }
                if let delimiter = stringDelimiter {
                    if char == "\\" && next == "(" {
                        interpolationStack.append((delimiter, 0))
                        stringDelimiter = nil
                        index += 2
                        continue
                    }
                    if char == "\\" { index += 2; continue }
                    if String(chars[index..<min(chars.count, index + delimiter.count)]) == delimiter {
                        stringDelimiter = nil
                        index += delimiter.count
                        continue
                    }
                    index += 1
                    continue
                }
                if char == "/" && next == "/" { commentLines.append(lineIndex); break }
                if char == "/" && next == "*" { inBlockComment += 1; index += 2; continue }
                if char == "\"" {
                    let isMultiline = index + 2 < chars.count && chars[index + 1] == "\"" && chars[index + 2] == "\""
                    stringDelimiter = isMultiline ? "\"\"\"" : "\""
                    index += isMultiline ? 3 : 1
                    continue
                }
                if !interpolationStack.isEmpty {
                    if char == "(" { interpolationStack[interpolationStack.count - 1].parentheses += 1 }
                    if char == ")" {
                        if let last = interpolationStack.last, last.parentheses == 0 {
                            interpolationStack.removeLast()
                            stringDelimiter = last.delimiter
                            index += 1
                            continue
                        }
                        interpolationStack[interpolationStack.count - 1].parentheses -= 1
                    }
                }
                if "{([".contains(char) { depth += 1 }
                if "})]".contains(char) { depth -= 1 }
                index += 1
            }
            if stringDelimiter == "\"" { stringDelimiter = nil }
        }
        depths.append(depth)
        return SourceScan(depths: depths, commentLines: commentLines)
    }
}

struct ViewParser {
    let lines: [String]

    private static let viewHeader = try! NSRegularExpression(
        pattern: #"^\s*(?:(?:private|fileprivate|internal|public)\s+)?struct\s+(\w+)(?:<[^>]*>)?\s*:[^{]*\b(View|ViewModifier|(?:NS|UI)View(?:Controller)?Representable)\b[^{]*\{"#
    )

    func views() -> [ViewDeclaration] {
        let depths = SourceScanner(lines: lines).scan().depths
        var result: [ViewDeclaration] = []
        for (index, line) in lines.enumerated() {
            let range = NSRange(line.startIndex..., in: line)
            guard let match = Self.viewHeader.firstMatch(in: line, range: range),
                  let nameRange = Range(match.range(at: 1), in: line),
                  let kindRange = Range(match.range(at: 2), in: line) else { continue }
            let bodyDepth = depths[index] + 1
            guard let closing = (index + 1..<lines.count).first(where: { depths[$0 + 1] < bodyDepth }) else { continue }
            let members = parseMembers(from: index + 1, to: closing, depth: bodyDepth, depths: depths)
            result.append(ViewDeclaration(name: String(line[nameRange]), kind: String(line[kindRange]), headerLine: index, closingLine: closing, members: members))
        }
        return result
    }

    private func parseMembers(from start: Int, to end: Int, depth: Int, depths: [Int]) -> [Member] {
        var members: [Member] = []
        var pending: [String] = []
        var pendingStart: Int?
        var blankLines = 0
        var index = start
        while index < end {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                if pending.isEmpty { blankLines += 1 } else { pending.append(line) }
                index += 1
                continue
            }
            if pending.isEmpty && isDirective(trimmed) {
                members.append(makeMember(lines: [line], firstLine: index, lastLine: index, blankLines: 0))
                index += 1
                continue
            }
            if pendingStart == nil { pendingStart = index }
            pending.append(line)
            let isLeadingOnly = trimmed.hasPrefix("//") || isAttributeOnly(trimmed)
            if isLeadingOnly {
                index += 1
                continue
            }
            var last = index
            while last + 1 < end, depths[last + 1] > depth || isContinuation(lines[last + 1]) {
                last += 1
                pending.append(lines[last])
            }
            members.append(makeMember(lines: pending, firstLine: pendingStart ?? index, lastLine: last, blankLines: blankLines))
            pending = []
            pendingStart = nil
            blankLines = 0
            index = last + 1
        }
        while pending.last?.trimmingCharacters(in: .whitespaces).isEmpty == true { pending.removeLast() }
        if !pending.isEmpty, let pendingStart {
            members.append(makeMember(lines: pending, firstLine: pendingStart, lastLine: pendingStart + pending.count - 1, blankLines: blankLines))
        }
        return members
    }

    private func isDirective(_ trimmed: String) -> Bool {
        ["#if", "#elseif", "#else", "#endif"].contains { trimmed == $0 || trimmed.hasPrefix($0 + " ") }
    }

    private func isAttributeOnly(_ trimmed: String) -> Bool {
        guard trimmed.hasPrefix("@") else { return false }
        let withoutAttributes = trimmed.replacingOccurrences(of: #"@\w+(\([^)]*\))?\s*"#, with: "", options: .regularExpression)
        return withoutAttributes.isEmpty
    }

    private func isContinuation(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("}") || trimmed.hasPrefix(".") || trimmed.hasPrefix(")") || trimmed.hasPrefix("]")
    }

    private func makeMember(lines: [String], firstLine: Int, lastLine: Int, blankLines: Int) -> Member {
        let code = lines
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("//") }
        let declaration = code.joined(separator: " ")
        let head = String(declaration.prefix { $0 != "{" && $0 != "=" })
        let wrapper = Wrapper.allCases.first { head.range(of: "@\($0.rawValue)\\b", options: .regularExpression) != nil }
        let tokens = head
            .replacingOccurrences(of: #"@\w+(\([^)]*\))?"#, with: "", options: .regularExpression)
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
        let isPrivate = tokens.contains("private") || tokens.contains("fileprivate")
        let isStatic = tokens.contains("static") || tokens.contains("class")
        let isOverride = tokens.contains("override")
        let keyword = tokens.first { ["let", "var", "func", "init", "struct", "enum", "class", "actor", "typealias", "protocol", "extension"].contains($0) }
        let name = keyword.flatMap { keyword in tokens.firstIndex(of: keyword).flatMap { tokens.indices.contains($0 + 1) ? tokens[$0 + 1] : nil } }?
            .components(separatedBy: CharacterSet(charactersIn: ":=({<")).first ?? ""
        let section: Section
        var missingPrivate = false
        if let wrapper {
            section = wrapper.section
            missingPrivate = wrapper.requiresPrivate && !isPrivate
        } else if keyword == "var" && name == "body" && !isStatic {
            section = .body
        } else if keyword == "let" && !isStatic {
            section = .stored
        } else if keyword == "var" && !isStatic {
            section = .stored
            missingPrivate = isComputed(declaration) && !isPrivate
        } else if keyword == "func" {
            section = .trailing
            missingPrivate = !isPrivate && !isOverride && !Self.protocolRequirements.contains(name)
        } else {
            section = .trailing
        }
        return Member(
            lines: lines,
            firstLine: firstLine,
            lastLine: lastLine,
            blankBefore: blankLines > 0,
            extraBlankLines: blankLines > 1,
            section: section,
            missingPrivate: missingPrivate,
            isDirective: code.first?.hasPrefix("#") == true,
            name: name
        )
    }

    private static let protocolRequirements: Set<String> = [
        "body", "sizeThatFits", "makeCoordinator",
        "makeNSView", "updateNSView", "dismantleNSView", "makeUIView", "updateUIView", "dismantleUIView",
        "makeNSViewController", "updateNSViewController", "dismantleNSViewController",
        "makeUIViewController", "updateUIViewController", "dismantleUIViewController",
    ]

    private func isComputed(_ declaration: String) -> Bool {
        guard let brace = declaration.firstIndex(of: "{"), !declaration[..<brace].contains("=") else { return false }
        let accessors = declaration[declaration.index(after: brace)...].trimmingCharacters(in: .whitespaces)
        return !accessors.hasPrefix("didSet") && !accessors.hasPrefix("willSet")
    }
}

struct Linter {
    let path: String
    let lines: [String]

    func violations() -> [Violation] {
        let views = ViewParser(lines: lines).views()
        return views.flatMap(violations(in:)) + fileViolations(views: views)
    }

    private func fileViolations(views: [ViewDeclaration]) -> [Violation] {
        var result: [Violation] = []
        for view in views.dropFirst() {
            result.append(Violation(file: path, line: view.headerLine + 1, message: "\(view.name) (\(view.kind)) doit être dans son propre fichier : une vue par fichier"))
        }
        for (index, line) in lines.enumerated() where line.contains("@ViewBuilder") {
            result.append(Violation(file: path, line: index + 1, message: "@ViewBuilder est interdit : extraire une vue dans son propre fichier"))
        }
        for index in SourceScanner(lines: lines).scan().commentLines {
            result.append(Violation(file: path, line: index + 1, message: "commentaire // interdit"))
        }
        return result
    }

    private func violations(in view: ViewDeclaration) -> [Violation] {
        var result: [Violation] = []
        var highest: Member?
        let members = view.members.filter { !$0.isDirective }
        for (index, member) in members.enumerated() {
            let line = member.firstLine + 1
            if member.missingPrivate {
                result.append(Violation(file: path, line: line, message: "\(view.name).\(member.name) doit être déclaré private (\(member.section.title))"))
            }
            if let previous = highest, member.section < previous.section {
                result.append(Violation(file: path, line: line, message: "\(view.name).\(member.name) (\(member.section.title)) doit précéder \(previous.name) (\(previous.section.title))"))
            } else {
                highest = member
            }
            guard index > 0 else { continue }
            let previous = members[index - 1]
            if previous.section != member.section && previous.section < member.section && !member.blankBefore {
                result.append(Violation(file: path, line: line, message: "\(view.name).\(member.name) doit être séparé de la section précédente par une ligne vide"))
            }
            if member.extraBlankLines {
                result.append(Violation(file: path, line: line, message: "\(view.name).\(member.name) doit être précédé d’une seule ligne vide"))
            }
        }
        return result
    }

    func fixed() -> [String] {
        var output = lines
        for _ in 0..<100 {
            guard let fix = nextFix(in: output) else { break }
            output.replaceSubrange(fix.range, with: fix.lines)
        }
        return output
    }

    private func nextFix(in source: [String]) -> (range: Range<Int>, lines: [String])? {
        for view in ViewParser(lines: source).views() where !view.members.contains(where: \.isDirective) {
            guard let first = view.members.first, let last = view.members.last, !violations(in: view).isEmpty else { continue }
            let range = first.firstLine..<(last.lastLine + 1)
            let rebuilt = rebuilt(view.members)
            if Array(source[range]) != rebuilt { return (range, rebuilt) }
        }
        return nil
    }

    private func rebuilt(_ members: [Member]) -> [String] {
        let ordered = members.enumerated()
            .sorted { ($0.element.section, $0.offset) < ($1.element.section, $1.offset) }
            .map(\.element)
        var result: [String] = []
        for (index, member) in ordered.enumerated() {
            if index > 0 {
                let sameSection = ordered[index - 1].section == member.section
                if !sameSection || member.blankBefore { result.append("") }
            }
            result.append(contentsOf: member.missingPrivate ? addingPrivate(to: member.lines) : member.lines)
        }
        return result
    }

    private func addingPrivate(to lines: [String]) -> [String] {
        let keyword = #"\b((?:static\s+)?(?:var|let|func))\b"#
        guard let index = lines.firstIndex(where: { $0.range(of: keyword, options: .regularExpression) != nil }) else { return lines }
        var copy = lines
        copy[index] = copy[index].replacingOccurrences(of: keyword, with: "private $1", options: .regularExpression, range: copy[index].range(of: keyword, options: .regularExpression))
        return copy
    }
}

func swiftFiles(in paths: [String]) -> [String] {
    paths.flatMap { path -> [String] in
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else { return [] }
        guard isDirectory.boolValue else { return path.hasSuffix(".swift") ? [path] : [] }
        let enumerator = FileManager.default.enumerator(atPath: path)
        return (enumerator?.allObjects as? [String] ?? [])
            .filter { $0.hasSuffix(".swift") }
            .sorted()
            .map { (path as NSString).appendingPathComponent($0) }
    }
}

let arguments = Array(CommandLine.arguments.dropFirst())
let shouldFix = arguments.contains("--fix")
let roots = arguments.filter { $0 != "--fix" }
let paths = roots.isEmpty ? ["Heka"] : roots
let missing = paths.filter { !FileManager.default.fileExists(atPath: $0) }
guard missing.isEmpty else {
    missing.forEach { print("error: \($0) n’existe pas") }
    exit(2)
}
let files = swiftFiles(in: paths)
var remaining: [Violation] = []

for file in files {
    guard let source = try? String(contentsOfFile: file, encoding: .utf8) else { continue }
    var lines = source.components(separatedBy: "\n")
    if shouldFix {
        let fixed = Linter(path: file, lines: lines).fixed()
        if fixed != lines {
            try fixed.joined(separator: "\n").write(toFile: file, atomically: true, encoding: .utf8)
            print("fixed \(file)")
            lines = fixed
        }
    }
    remaining += Linter(path: file, lines: lines).violations()
}

for violation in remaining {
    print("\(violation.file):\(violation.line): error: \(violation.message)")
}
exit(remaining.isEmpty ? 0 : 1)
