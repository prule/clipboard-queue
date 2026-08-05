import SwiftUI
import AppKit

extension Color {
    /// "#0a68d0" / "0a68d0" / "0a68d012" (8-digit = RGBA, matching the design's `accent + "12"` idiom).
    init(hex: String) {
        var s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let hasAlpha = s.count == 8
        let r = Double((v >> (hasAlpha ? 24 : 16)) & 0xff) / 255
        let g = Double((v >> (hasAlpha ? 16 : 8)) & 0xff) / 255
        let b = Double((v >> (hasAlpha ? 8 : 0)) & 0xff) / 255
        let a = hasAlpha ? Double(v & 0xff) / 255 : 1
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

enum Theme {
    // Surfaces
    static let canvas = Color(hex: "e8e8ea")
    static let sidebar = Color(hex: "f0f0f2")
    static let paneBG = Color.white
    static let statusBarBG = Color(hex: "fafafb")
    static let popoverBG = Color(hex: "fcfcfd")

    // Hairlines
    static let sidebarBorder = Color(hex: "dcdce0")
    static let paneBorder = Color(hex: "e6e6ea")
    static let rowBorder = Color(hex: "f2f2f4")
    static let cardBorder = Color(hex: "e2e2e6")
    static let controlBorder = Color(hex: "d2d2d8")
    static let hairline = Color(hex: "eeeef1")

    // Text
    static let ink = Color(hex: "1b1b1f")
    static let inkSoft = Color(hex: "2a2a32")
    static let inkMuted = Color(hex: "3a3a42")
    static let label = Color(hex: "4a4a52")
    static let mono2 = Color(hex: "5a5a62")
    static let meta = Color(hex: "8a8a90")
    static let metaLight = Color(hex: "9a9aa2")
    static let pending = Color(hex: "a8a8b0")
    static let doneTag = Color(hex: "b4b4bc")
    static let doneNum = Color(hex: "c2c2c8")

    // Interaction
    static let sidebarHover = Color(hex: "e2e2e6")
    static let controlHover = Color(hex: "f4f4f6")
    static let menuHover = Color(hex: "eeeef1")
    static let pausedButton = Color(hex: "5a5a62")

    // Traffic lights
    static let tlRed = Color(hex: "ff5f57")
    static let tlYellow = Color(hex: "febc2e")
    static let tlGreen = Color(hex: "28c840")

    /// The design specifies Inconsolata; fall back to the system monospace when it isn't installed.
    static let hasInconsolata = NSFont(name: "Inconsolata", size: 12) != nil

    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        hasInconsolata
            ? .custom("Inconsolata", fixedSize: size).weight(weight)
            : .system(size: size, weight: weight, design: .monospaced)
    }

    static func ui(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    static func nsMono(_ size: CGFloat, _ weight: NSFont.Weight = .regular) -> NSFont {
        if hasInconsolata, let f = NSFont(name: "Inconsolata", size: size) { return f }
        return NSFont.monospacedSystemFont(ofSize: size, weight: weight)
    }
}

/// `letter-spacing` in the design is em-relative; SwiftUI's `.tracking` is in points.
extension View {
    func tracking(em: CGFloat, size: CGFloat) -> some View { self.tracking(em * size) }
}