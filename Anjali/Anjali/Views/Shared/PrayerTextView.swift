import SwiftUI

/// Renders a prayer's sacred text honouring the user's script preference.
/// Uses semantic font styles so the text scales with Dynamic Type.
struct PrayerTextView: View {
    let prayer: Prayer
    let scriptPreference: ScriptPreference
    let theme: ThemePalette
    /// Dynamic-Type text style for the primary (Devanagari) line.
    var primaryStyle: Font.TextStyle = .title

    var body: some View {
        VStack(spacing: 16) {
            if showsDevanagari {
                Text(prayer.primaryText.devanagari)
                    .font(.system(primaryStyle, design: .serif))
                    .foregroundStyle(theme.foreground)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
            }
            if showsTransliteration {
                Text(prayer.transliteration)
                    .font(.system(showsDevanagari ? .subheadline : .title3, design: .serif))
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
