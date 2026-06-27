import Foundation

/// A parsed in-app destination from an `anjali://` URL or a notification.
///
/// Supported forms:
/// - `anjali://moment/{id}`  → open the Moments flow for a moment
/// - `anjali://prayer/{id}`  → open a specific prayer
enum DeepLink: Equatable {
    case moment(Moment)
    case prayer(prayerID: String)

    static let scheme = "anjali"

    init?(url: URL) {
        guard url.scheme == DeepLink.scheme else { return nil }
        // host is the kind, first path component is the id.
        let kind = url.host
        let id = url.pathComponents.first(where: { $0 != "/" })

        switch kind {
        case "moment":
            guard let id, let moment = Moment(rawValue: id) else { return nil }
            self = .moment(moment)
        case "prayer":
            guard let id, !id.isEmpty else { return nil }
            self = .prayer(prayerID: id)
        default:
            return nil
        }
    }

    var url: URL? {
        switch self {
        case .moment(let moment):
            return URL(string: "\(DeepLink.scheme)://moment/\(moment.rawValue)")
        case .prayer(let id):
            return URL(string: "\(DeepLink.scheme)://prayer/\(id)")
        }
    }
}
