import SwiftUI

/// A simple list of prayers under a heading. Tapping a row opens the player.
struct PrayerListView: View {
    let title: String
    let prayers: [Prayer]
    let onSelect: (Prayer) -> Void

    var body: some View {
        List {
            if prayers.isEmpty {
                Text("No prayers here yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(prayers) { prayer in
                    Button {
                        onSelect(prayer)
                    } label: {
                        PrayerRow(prayer: prayer)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// A compact row describing a prayer.
struct PrayerRow: View {
    let prayer: Prayer

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: prayer.deity?.symbolName ?? "flame")
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 3) {
                Text(prayer.title)
                    .font(.headline)
                Text(prayer.transliteration)
                    .font(.subheadline)
                    .italic()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(prayer.durationLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
