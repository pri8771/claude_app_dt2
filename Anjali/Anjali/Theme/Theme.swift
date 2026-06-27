import SwiftUI

extension Color {
    /// Create a colour from a hex string such as "#20265F" or "20265F".
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r, g, b, a: Double
        switch cleaned.count {
        case 8: // RRGGBBAA
            r = Double((value & 0xFF000000) >> 24) / 255
            g = Double((value & 0x00FF0000) >> 16) / 255
            b = Double((value & 0x0000FF00) >> 8) / 255
            a = Double(value & 0x000000FF) / 255
        default: // RRGGBB
            r = Double((value & 0xFF0000) >> 16) / 255
            g = Double((value & 0x00FF00) >> 8) / 255
            b = Double(value & 0x0000FF) / 255
            a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

/// The full visual + copy theme for a single time band. Derived purely from a
/// `TimeContext`, so it is deterministic and testable.
struct ThemePalette: Equatable {
    let background: Color
    let accent: Color
    /// The eyebrow label shown above the headline ("Begin with light").
    let eyebrow: String
    let headline: String
    let subheadline: String
    /// Whether the background is light (so foreground text should be dark).
    let prefersDarkForeground: Bool

    /// Foreground colour for primary text, chosen for contrast.
    var foreground: Color {
        prefersDarkForeground ? Color(hex: "1A1208") : Color.white
    }

    /// A muted variant of the foreground for secondary text.
    var secondaryForeground: Color {
        foreground.opacity(0.7)
    }

    static func palette(for context: TimeContext) -> ThemePalette {
        switch context {
        case .dawn:
            return ThemePalette(
                background: Color(hex: "20265F"),
                accent: Color(hex: "F3B85E"),
                eyebrow: "Begin with light",
                headline: "The day is waking",
                subheadline: "A breath before everything begins.",
                prefersDarkForeground: false
            )
        case .morning:
            return ThemePalette(
                background: Color(hex: "FFF4DA"),
                accent: Color(hex: "F29A24"),
                eyebrow: "Speak with clarity",
                headline: "Carry calm forward",
                subheadline: "A steady word for what's ahead.",
                prefersDarkForeground: true
            )
        case .midday:
            return ThemePalette(
                background: Color(hex: "FFF4DA"),
                accent: Color(hex: "F29A24"),
                eyebrow: "Speak with clarity",
                headline: "A pause at midday",
                subheadline: "Steady yourself in the middle of things.",
                prefersDarkForeground: true
            )
        case .sunset:
            return ThemePalette(
                background: Color(hex: "5B1E2D"),
                accent: Color(hex: "F0A94E"),
                eyebrow: "Return with gratitude",
                headline: "Set down the day",
                subheadline: "A moment to give thanks.",
                prefersDarkForeground: false
            )
        case .night:
            return ThemePalette(
                background: Color(hex: "091426"),
                accent: Color(hex: "E8A93A"),
                eyebrow: "Rest in peace",
                headline: "Let the day settle",
                subheadline: "A quiet close before sleep.",
                prefersDarkForeground: false
            )
        }
    }
}
