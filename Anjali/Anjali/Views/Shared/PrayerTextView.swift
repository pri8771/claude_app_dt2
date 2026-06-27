import SwiftUI

/// Renders a prayer's sacred text honouring the user's script preference.
struct PrayerTextView: View {
    let prayer: Prayer
    let scriptPreference: ScriptPreference
    let theme: ThemePalette
    /// Base size for the Devanagari line (28–36pt per spec).
    var devanagariSize: CGFloat = 32

    var body: some View {
        VStack(spacing: 16) {
            if showsDevanagari {
                Text(prayer.primaryText.devanagari)
                    .font(.system(size: devanagariSize, weight: .regular, design: .serif))
                    .foregroundStyle(theme.foreground)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
            }
            if showsTransliteration {
                Text(prayer.transliteration)
                    .font(.system(size: showsDevanagari ? 18 : 26, weight: .regular, design: .serif))
                    .italic()
                    .foregroundStyle(showsDevanagari ? theme.secondaryForeground : theme.foreground)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var showsDevanagari: Bool {
        scriptPreference == .devanagari || scriptPreference == .both
    }

    private var showsTransliteration: Bool {
        scriptPreference == .transliteration || scriptPreference == .both
    }
}
