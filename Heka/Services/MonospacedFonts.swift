import AppKit

@MainActor enum MonospacedFonts {
    private static var cachedFamilies: [String]?

    static var families: [String] {
        if let cachedFamilies { return cachedFamilies }
        let families = NSFontManager.shared.availableFontFamilies.filter { family in
            NSFont(name: family, size: 13)?.isFixedPitch ?? false
        }
        cachedFamilies = families
        return families
    }

    static func reload() -> [String] {
        cachedFamilies = nil
        return families
    }
}
