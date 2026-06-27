import Foundation

/// Errors surfaced while loading bundled prayer content.
enum PrayerDataError: Error, Equatable {
    case resourceNotFound(String)
    case unreadable(String)
}

/// Loads and validates prayer content from a bundled JSON file.
///
/// Robustness is a hard requirement: a single malformed entry must never crash
/// the app. The loader decodes the array element-by-element and silently skips
/// entries that fail to decode or that fail field validation, returning only
/// the well-formed prayers.
struct PrayerDataLoader {

    /// The resource (without extension) that holds seed prayers.
    static let defaultResourceName = "prayers"

    /// Load prayers from a bundle. Throws only when the resource is missing or
    /// fundamentally unreadable — never for individual bad records.
    static func loadPrayers(
        resourceName: String = defaultResourceName,
        bundle: Bundle = .main
    ) throws -> [Prayer] {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw PrayerDataError.resourceNotFound(resourceName)
        }
        guard let data = try? Data(contentsOf: url) else {
            throw PrayerDataError.unreadable(resourceName)
        }
        return loadPrayers(from: data)
    }

    /// Decode prayers from raw JSON data, skipping malformed entries.
    static func loadPrayers(from data: Data) -> [Prayer] {
        let decoder = JSONDecoder()

        // First try the strict path: a clean array of prayers.
        if let prayers = try? decoder.decode([Prayer].self, from: data) {
            return prayers.filter(isValid).sorted(by: ordering)
        }

        // Fall back to lenient, per-element decoding so one bad record does not
        // discard the entire file.
        guard let raw = try? decoder.decode([FailablePrayer].self, from: data) else {
            return []
        }
        return raw
            .compactMap { $0.value }
            .filter(isValid)
            .sorted(by: ordering)
    }

    /// Field-level validation beyond what `Codable` enforces.
    static func isValid(_ prayer: Prayer) -> Bool {
        guard !prayer.id.trimmingCharacters(in: .whitespaces).isEmpty,
              !prayer.title.trimmingCharacters(in: .whitespaces).isEmpty,
              !prayer.primaryText.devanagari.trimmingCharacters(in: .whitespaces).isEmpty,
              !prayer.meaning.trimmingCharacters(in: .whitespaces).isEmpty,
              !prayer.sourceTitle.trimmingCharacters(in: .whitespaces).isEmpty,
              prayer.durationSeconds > 0,
              !prayer.availableModes.isEmpty
        else {
            return false
        }
        return true
    }

    private static func ordering(_ a: Prayer, _ b: Prayer) -> Bool {
        if a.sortOrder != b.sortOrder { return a.sortOrder < b.sortOrder }
        return a.id < b.id
    }
}

/// Wrapper that lets a single bad array element decode to `nil` instead of
/// throwing and aborting the whole array.
private struct FailablePrayer: Decodable {
    let value: Prayer?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.value = try? container.decode(Prayer.self)
    }
}
