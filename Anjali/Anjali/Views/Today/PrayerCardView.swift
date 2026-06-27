import SwiftUI

/// The single contextual prayer card on Today.
struct PrayerCardView: View {
    let prayer: Prayer
    let theme: ThemePalette
    let onBegin: () -> Void

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
                ForEach(prayer.availableModes) { mode in
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

            Button(action: onBegin) {
                Text("Begin")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(AnjaliPrimaryButtonStyle(theme: theme))
        }
        .padding(22)
        .background(theme.foreground.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(theme.foreground.opacity(0.10), lineWidth: 1)
        )
    }
}
