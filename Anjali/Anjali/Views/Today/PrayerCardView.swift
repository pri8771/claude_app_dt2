import SwiftUI

/// The single contextual prayer card on Today, with three actions:
///  - Begin  (primary)   — open the player in the preferred mode
///  - Silent (secondary) — open the player forced to Silent
///  - Change (tertiary)  — swap to the next contextual prayer, no player
struct PrayerCardView: View {
    let prayer: Prayer
    let theme: ThemePalette
    /// Whether a "Change" action is available (more than one prayer today).
    let canChange: Bool
    let onBegin: () -> Void
    let onSilent: () -> Void
    let onChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                if let deity = prayer.deity {
                    InfoChip(text: deity.displayName, systemImage: deity.symbolName, tint: theme.accent)
                }
                Spacer()
                InfoChip(text: prayer.durationLabel, systemImage: "clock", tint: theme.accent)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(prayer.title)
                    .font(.system(size: 26, weight: .semibold, design: .serif))
                    .foregroundStyle(theme.foreground)
                Text(prayer.transliteration)
                    .font(.callout)
                    .italic()
                    .foregroundStyle(theme.secondaryForeground)
            }

            // Available modes for this prayer.
            HStack(spacing: 8) {
                ForEach(prayer.playableModes) { mode in
                    InfoChip(text: mode.displayName, systemImage: mode.symbolName, tint: theme.foreground.opacity(0.9))
                }
            }

            Text(prayer.meaning)
                .font(.body)
                .foregroundStyle(theme.foreground.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            Text("Source: \(prayer.sourceTitle)")
                .font(.caption2)
                .foregroundStyle(theme.secondaryForeground)

            actions
        }
        .padding(22)
        .background(theme.foreground.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(theme.foreground.opacity(0.10), lineWidth: 1)
        )
    }

    private var actions: some View {
        VStack(spacing: 12) {
            // Primary
            Button(action: onBegin) {
                Text("Begin")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(AnjaliPrimaryButtonStyle(theme: theme))
            .accessibilityLabel("Begin prayer")
            .accessibilityHint("Opens the prayer in your preferred mode")

            // Secondary row: Silent + Change
            HStack(spacing: 12) {
                Button(action: onSilent) {
                    Label("Silent", systemImage: "moon")
                        .frame(maxWidth: .infinity)
                }
                .secondaryCardAction(theme: theme)
                .accessibilityLabel("Begin in silent mode")
                .accessibilityHint("Opens the prayer as text only, no audio")

                if canChange {
                    Button(action: onChange) {
                        Label("Change", systemImage: "arrow.triangle.2.circlepath")
                            .frame(maxWidth: .infinity)
                    }
                    .secondaryCardAction(theme: theme)
                    .accessibilityLabel("Change prayer")
                    .accessibilityHint("Shows the next prayer for this moment")
                }
            }
        }
    }
}

private extension View {
    /// Smaller, secondary styling for the Silent / Change actions.
    func secondaryCardAction(theme: ThemePalette) -> some View {
        self
            .font(.subheadline.weight(.medium))
            .padding(.vertical, 12)
            .background(theme.foreground.opacity(0.12))
            .foregroundStyle(theme.foreground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .buttonStyle(.plain)
    }
}
