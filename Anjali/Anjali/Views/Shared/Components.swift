import SwiftUI
import Foundation

/// The primary call-to-action button styled for a given theme.
struct AnjaliPrimaryButtonStyle: ButtonStyle {
    let theme: ThemePalette

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 16)
            .background(theme.accent)
            .foregroundStyle(Color(hex: "1A1208"))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// A small pill used for duration and metadata.
struct InfoChip: View {
    let systemImage: String?
    let text: String
    var tint: Color

    init(text: String, systemImage: String? = nil, tint: Color) {
        self.text = text
        self.systemImage = systemImage
        self.tint = tint
    }

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(text)
        }
        .font(.caption.weight(.medium))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tint.opacity(0.18))
        .foregroundStyle(tint)
        .clipShape(Capsule())
    }
}

/// A selectable mode chip (Listen / Chant / Silent).
struct ModeChip: View {
    let mode: PlayMode
    let isSelected: Bool
    let theme: ThemePalette
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: mode.symbolName)
                Text(mode.displayName)
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(isSelected ? theme.accent : theme.foreground.opacity(0.12))
            .foregroundStyle(isSelected ? Color(hex: "1A1208") : theme.foreground)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// A subtle ring with a flame at its head that fills with progress.
/// Used as the player's progress indicator.
struct FlameProgressView: View {
    /// 0...1
    let progress: Double
    let theme: ThemePalette

    var body: some View {
        ZStack {
            Circle()
                .stroke(theme.foreground.opacity(0.12), lineWidth: 6)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(
                    theme.accent,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.2), value: progress)
            Image(systemName: "flame.fill")
                .font(.system(size: 34))
                .foregroundStyle(theme.accent)
                .shadow(color: theme.accent.opacity(0.6), radius: 12)
                .scaleEffect(1 + 0.05 * sin(progress * .pi * 8))
        }
    }
}
