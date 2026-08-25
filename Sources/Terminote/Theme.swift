import AppKit
import SwiftUI

struct Theme {
    private static let black = Color(hex: 0x000000)
    private static let blue = Color(hex: 0x4689CC)

    static let panelBackground = black
    static let editorBackground = black
    static let elevatedBackground = black
    static let border = blue.opacity(0.55)
    static let primaryText = Color.white.opacity(0.92)
    static let mutedText = Color.white.opacity(0.5)
    static let caret = blue
    static let selectionBackground = blue.opacity(0.35)
    static let currentLineHighlight = blue.opacity(0.10)
    static let accent = blue
    static let destructive = blue
    static let cornerRadius: CGFloat = 24

    static func editorFont(size: CGFloat = 13) -> NSFont {
        for family in ["Zed Mono", "JetBrains Mono", "SF Mono"] {
            if let font = NSFont(name: family, size: size) {
                return font
            }
        }
        return .monospacedSystemFont(ofSize: size, weight: .regular)
    }
}

extension Color {
    fileprivate init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

extension NSColor {
    convenience init(theme color: Color) {
        self.init(color)
    }
}
