import Foundation

extension String {
    var bracketedPasteSafe: String {
        String(String.UnicodeScalarView(unicodeScalars.filter(\.isAllowedInBracketedPaste)))
    }
}

private extension Unicode.Scalar {
    var isAllowedInBracketedPaste: Bool {
        switch value {
        case 0x09, 0x0A, 0x0D: true
        case 0x00...0x1F, 0x7F...0x9F: false
        default: true
        }
    }
}
