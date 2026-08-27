import AppKit
import SwiftUI

struct ThemeConfiguration: Codable, Equatable, Sendable {
    var backgroundRGB: UInt32
    var outlineRGB: UInt32
    var opacity: Double
    var usesLiquidGlass: Bool

    static let `default` = ThemeConfiguration(
        backgroundRGB: 0x000000,
        outlineRGB: 0x4689CC,
        opacity: 1,
        usesLiquidGlass: false
    )

    var normalized: ThemeConfiguration {
        var copy = self
        copy.backgroundRGB &= 0xFFFFFF
        copy.outlineRGB &= 0xFFFFFF
        copy.opacity = min(max(copy.opacity, 0.25), 1)
        return copy
    }

    var backgroundColor: Color { Color(rgb: backgroundRGB) }
    var outlineColor: Color { Color(rgb: outlineRGB) }
}

struct SavedTheme: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let savedAt: Date
    let configuration: ThemeConfiguration
}

struct Theme {
    static let destructive = Color(red: 0.95, green: 0.28, blue: 0.30)
    static let cornerRadius: CGFloat = 24

    static func panelBackground(_ theme: ThemeConfiguration) -> Color {
        theme.backgroundColor.opacity(theme.opacity)
    }

    static func editorBackground(_ theme: ThemeConfiguration) -> Color {
        panelBackground(theme)
    }

    static func elevatedBackground(_ theme: ThemeConfiguration) -> Color {
        theme.backgroundColor.opacity(theme.opacity)
    }

    static func border(_ theme: ThemeConfiguration) -> Color {
        theme.outlineColor.opacity(0.65)
    }

    static func primaryText(_ theme: ThemeConfiguration) -> Color {
        prefersLightText(theme) ? Color.white.opacity(0.92) : Color.black.opacity(0.86)
    }

    static func mutedText(_ theme: ThemeConfiguration) -> Color {
        prefersLightText(theme) ? Color.white.opacity(0.52) : Color.black.opacity(0.52)
    }

    static func caret(_ theme: ThemeConfiguration) -> Color {
        theme.outlineColor
    }

    static func selectionBackground(_ theme: ThemeConfiguration) -> Color {
        theme.outlineColor.opacity(0.35)
    }

    static func preferredColorScheme(_ theme: ThemeConfiguration) -> ColorScheme {
        prefersLightText(theme) ? .dark : .light
    }

    static func usesLiquidGlass(_ theme: ThemeConfiguration) -> Bool {
        if #available(macOS 26.0, *) {
            return theme.usesLiquidGlass
        }
        return false
    }

    static func editorFont(size: CGFloat = 13) -> NSFont {
        for family in ["Zed Mono", "JetBrains Mono", "SF Mono"] {
            if let font = NSFont(name: family, size: size) {
                return font
            }
        }
        return .monospacedSystemFont(ofSize: size, weight: .regular)
    }

    private static func prefersLightText(_ theme: ThemeConfiguration) -> Bool {
        let red = Double((theme.backgroundRGB >> 16) & 0xFF) / 255
        let green = Double((theme.backgroundRGB >> 8) & 0xFF) / 255
        let blue = Double(theme.backgroundRGB & 0xFF) / 255
        let luminance = (0.299 * red) + (0.587 * green) + (0.114 * blue)
        return luminance < 0.58
    }
}

extension Color {
    init(rgb: UInt32) {
        self.init(
            .sRGB,
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255,
            opacity: 1
        )
    }

    var rgbValue: UInt32 {
        guard let color = NSColor(self).usingColorSpace(.sRGB) else { return 0 }
        let red = UInt32((min(max(color.redComponent, 0), 1) * 255).rounded())
        let green = UInt32((min(max(color.greenComponent, 0), 1) * 255).rounded())
        let blue = UInt32((min(max(color.blueComponent, 0), 1) * 255).rounded())
        return (red << 16) | (green << 8) | blue
    }
}

extension NSColor {
    convenience init(theme color: Color) {
        self.init(color)
    }
}
