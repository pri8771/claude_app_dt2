import Foundation

/// The five contextual time bands the app moves through across a day
/// (dawn, morning, midday, sunset, night). Each band drives the visual theme
/// and copy on the Today screen.
enum TimeContext: String, Codable, CaseIterable, Identifiable, Hashable {
    case dawn       // 04:30–07:59
    case morning    // 08:00–11:59
    case midday     // 12:00–15:59
    case sunset     // 16:00–19:59
    case night      // 20:00–04:29

    var id: String { rawValue }

    /// Human-facing name of the band.
    var displayName: String {
        switch self {
        case .dawn: return "Dawn"
        case .morning: return "Morning"
        case .midday: return "Midday"
        case .sunset: return "Sunset"
        case .night: return "Night"
        }
    }

    /// Moments naturally associated with this band. Used by the Today engine
    /// to infer a moment when the user has not chosen one explicitly.
    var inferredMoments: [Moment] {
        switch self {
        case .dawn: return [.dawn]
        case .morning: return [.beforeWork, .meeting, .study]
        case .midday: return [.meeting, .study, .beforeWork]
        case .sunset: return [.sunset, .gratitude]
        case .night: return [.sleep]
        }
    }
}

/// How often a prayer should surface in the Today rotation. Lets the engine
/// keep daily anchors present without letting everything repeat constantly.
enum RotationPolicy: String, Codable, CaseIterable, Hashable {
    /// Appears daily (e.g. Gayatri, Om Shanti, a simple Ganesha invocation,
    /// the evening lamp). Recent-completion penalties are softened for these.
    case dailyAnchor
    /// Normal Today rotation — the default for most prayers.
    case rotateOften
    /// A special intention or less common use; surfaces less frequently.
    case occasional
    /// Only when explicitly relevant (festival/seasonal). Reserved for later.
    case festivalSpecific
}

/// A "moment" is a situation in daily life a micro-prayer can accompany.
enum Moment: String, Codable, CaseIterable, Identifiable, Hashable {
    case dawn
    case leavingHome
    case beforeWork
    case meeting
    case study
    case travel
    case anxiety
    case gratitude
    case protection
    case sunset
    case sleep

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dawn: return "Dawn"
        case .leavingHome: return "Leaving home"
        case .beforeWork: return "Before work"
        case .meeting: return "Meeting"
        case .study: return "Study"
        case .travel: return "Travel"
        case .anxiety: return "Anxiety"
        case .gratitude: return "Gratitude"
        case .protection: return "Protection"
        case .sunset: return "Sunset"
        case .sleep: return "Sleep"
        }
    }

    /// SF Symbol used in browse lists.
    var symbolName: String {
        switch self {
        case .dawn: return "sunrise"
        case .leavingHome: return "door.left.hand.open"
        case .beforeWork: return "briefcase"
        case .meeting: return "person.2"
        case .study: return "book"
        case .travel: return "airplane"
        case .anxiety: return "wind"
        case .gratitude: return "hands.sparkles"
        case .protection: return "shield"
        case .sunset: return "sunset"
        case .sleep: return "moon.stars"
        }
    }
}

/// Deities a prayer may be addressed to.
enum Deity: String, Codable, CaseIterable, Identifiable, Hashable {
    case ganesha
    case shiva
    case vishnu
    case krishna
    case hanuman
    case devi
    case lakshmi
    case saraswati
    case surya

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ganesha: return "Ganesha"
        case .shiva: return "Shiva"
        case .vishnu: return "Vishnu"
        case .krishna: return "Krishna"
        case .hanuman: return "Hanuman"
        case .devi: return "Devi"
        case .lakshmi: return "Lakshmi"
        case .saraswati: return "Saraswati"
        case .surya: return "Surya"
        }
    }

    var symbolName: String {
        switch self {
        case .ganesha: return "sparkle"
        case .shiva: return "drop"
        case .vishnu: return "circle.hexagongrid"
        case .krishna: return "music.note"
        case .hanuman: return "figure.run"
        case .devi: return "flame"
        case .lakshmi: return "leaf"
        case .saraswati: return "book.closed"
        case .surya: return "sun.max"
        }
    }
}

/// An intention is the inner aim a prayer supports. Lighter-weight than a
/// Moment; used for scoring and future filtering.
enum Intention: String, Codable, CaseIterable, Identifiable, Hashable {
    case clarity
    case gratitude
    case protection
    case peace
    case focus
    case courage
    case prosperity
    case wisdom
    case devotion

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }
}

/// How a prayer can be experienced in the player.
enum PlayMode: String, Codable, CaseIterable, Identifiable, Hashable {
    case listen
    case chant
    case silent

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .listen: return "Listen"
        case .chant: return "Chant"
        case .silent: return "Silent"
        }
    }

    var symbolName: String {
        switch self {
        case .listen: return "speaker.wave.2"
        case .chant: return "text.quote"
        case .silent: return "moon"
        }
    }
}

/// User preference for how Sanskrit text is rendered.
enum ScriptPreference: String, Codable, CaseIterable, Identifiable, Hashable {
    case devanagari
    case transliteration
    case both

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .devanagari: return "Devanagari"
        case .transliteration: return "Transliteration"
        case .both: return "Both"
        }
    }
}
