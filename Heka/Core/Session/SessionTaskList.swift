import Foundation

enum SessionTaskList {
    private struct Fence {
        let character: Character
        let length: Int
        let container: Int

        init?(_ text: Substring, container: Int) {
            guard let first = text.first, first == "`" || first == "~" else { return nil }
            let length = text.prefix { $0 == first }.count
            guard length >= 3, first == "~" || !text.dropFirst(length).contains("`") else { return nil }
            character = first
            self.length = length
            self.container = container
        }

        func isClosed(by line: Line) -> Bool {
            let run = line.text.prefix { $0 == character }.count
            return line.indent < container + 4 && run >= length && line.text.dropFirst(run).allSatisfy(\.isWhitespace)
        }
    }

    private struct Line {
        let indent: Int
        let text: Substring
        let listContent: (indent: Int, text: Substring)?
        let isThematicBreak: Bool

        init(_ line: Substring) {
            let indentation = line.prefix { $0 == " " || $0 == "\t" }
            indent = SessionTaskList.column(after: indentation, from: 0)
            text = line.dropFirst(indentation.count)
            isThematicBreak = text.first.map { "-*_".contains($0) } == true && Self.isThematicBreak(text)
            listContent = isThematicBreak ? nil : Self.listMarker(in: text).map { [indent, text] marker in
                (SessionTaskList.column(after: marker, from: indent), text[marker.endIndex...])
            }
        }

        var isBlank: Bool { text.allSatisfy(\.isWhitespace) }

        var isSingleLineBlock: Bool { isHeading || isThematicBreak }

        private var isHeading: Bool {
            let level = text.prefix { $0 == "#" }.count
            return (1...6).contains(level) && text.dropFirst(level).first.map(Self.isSpacing) != false
        }

        var startsBlock: Bool { listContent != nil || isSingleLineBlock || text.hasPrefix(">") || Fence(text, container: 0) != nil }

        private static func listMarker(in text: Substring) -> Substring? {
            let digits = text.prefix { $0.isASCII && $0.isNumber }.count
            let markerLength = digits == 0 ? 1 : digits + 1
            guard let delimiter = text.dropFirst(markerLength - 1).first,
                  digits == 0 ? "-*+".contains(delimiter) : ".)".contains(delimiter) else { return nil }
            let spacing = text.dropFirst(markerLength).prefix(while: isSpacing).count
            return spacing == 0 ? nil : text.prefix(markerLength + spacing)
        }

        private static func isSpacing(_ character: Character) -> Bool {
            character == " " || character == "\t"
        }

        private static func isThematicBreak(_ text: Substring) -> Bool {
            let marks = text.filter { !$0.isWhitespace }
            return marks.count >= 3 && Set(marks).count == 1
        }
    }

    private struct Parser {
        private var containers: [Int] = []
        private var fence: Fence?
        private var inParagraph = false
        private var inIndentedCode = false

        private var container: Int { containers.last ?? 0 }

        mutating func allowsCheckbox(on line: Line) -> Bool {
            if let open = fence {
                if line.isBlank || line.indent >= open.container {
                    if open.isClosed(by: line) { fence = nil }
                    return false
                }
                fence = nil
            }
            guard !line.isBlank else {
                inParagraph = false
                return false
            }
            if !inParagraph || line.startsBlock { containers.removeAll { $0 > line.indent } }
            inIndentedCode = line.indent >= container + 4 && (inIndentedCode || !inParagraph)
            if inIndentedCode || line.indent < container + 4 && open(Fence(line.text, container: container)) {
                inParagraph = false
                return false
            }
            guard let content = line.listContent, line.indent < container + 4 else {
                inParagraph = !line.isSingleLineBlock
                return false
            }
            containers.append(content.indent)
            inParagraph = !open(Fence(content.text, container: content.indent))
            return inParagraph
        }

        private mutating func open(_ candidate: Fence?) -> Bool {
            fence = candidate
            return candidate != nil
        }
    }

    static func replacingCheckboxes(in markdown: String) -> String {
        let item = /^(\s*(?:[-*+]|\d+[.)])\s+)\[([ xX])\](?=\s)/
        var parser = Parser()
        return markdown.split(separator: "\n", omittingEmptySubsequences: false).map { line -> Substring in
            guard parser.allowsCheckbox(on: Line(line)), let match = line.prefixMatch(of: item) else { return line }
            return match.1 + (match.2 == " " ? "☐" : "☑") + line[match.range.upperBound...]
        }.joined(separator: "\n")
    }

    fileprivate static func column(after text: Substring, from start: Int) -> Int {
        text.reduce(start) { $0 + ($1 == "\t" ? 4 - $0 % 4 : 1) }
    }
}
