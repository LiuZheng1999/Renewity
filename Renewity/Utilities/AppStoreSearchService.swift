import Foundation

nonisolated struct AppStoreSearchResult: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let seller: String
    let artworkURL: URL
    let genre: String

    var category: SubscriptionCategory {
        SubscriptionCategory.fromAppStoreGenre(genre)
    }
}

nonisolated enum AppStoreSearchService {
    static func search(_ query: String) async throws -> [AppStoreSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }

        async let ios = lookup(term: trimmed, entity: "software")
        async let mac = lookup(term: trimmed, entity: "macSoftware")
        let combined = try await ios + mac

        var seenIDs = Set<Int>()
        var seenNames = Set<String>()
        var unique: [AppStoreSearchResult] = []
        for item in combined {
            let key = item.name.lowercased()
            guard seenIDs.insert(item.id).inserted, seenNames.insert(key).inserted else { continue }
            unique.append(item)
        }
        return Array(unique.prefix(20))
    }

    private static func lookup(term: String, entity: String) async throws -> [AppStoreSearchResult] {
        var components = URLComponents(string: "https://itunes.apple.com/search")!
        components.queryItems = [
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "entity", value: entity),
            URLQueryItem(name: "limit", value: "15"),
            URLQueryItem(name: "country", value: "us"),
            URLQueryItem(name: "lang", value: "en_us"),
        ]
        guard let url = components.url else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let payload = try JSONDecoder().decode(iTunesResponse.self, from: data)
        return payload.results.compactMap { AppStoreSearchResult($0) }
    }
}

nonisolated private struct iTunesResponse: Decodable, Sendable {
    var results: [iTunesApp]
}

nonisolated private struct iTunesApp: Decodable, Sendable {
    var trackId: Int
    var trackName: String
    var artistName: String
    var artworkUrl100: String?
    var artworkUrl512: String?
    var primaryGenreName: String?
}

nonisolated private extension AppStoreSearchResult {
    init?(_ app: iTunesApp) {
        let artwork = app.artworkUrl512 ?? app.artworkUrl100
        guard let artwork, let url = URL(string: artwork) else { return nil }
        id = app.trackId
        name = Self.displayName(trackName: app.trackName)
        seller = app.artistName
        artworkURL = url
        genre = app.primaryGenreName ?? ""
    }

    static func displayName(trackName: String) -> String {
        let trimmed = trackName.trimmingCharacters(in: .whitespacesAndNewlines)
        for separator in [": ", " - ", " – "] {
            if let range = trimmed.range(of: separator) {
                let prefix = String(trimmed[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                if (2...28).contains(prefix.count) {
                    return prefix
                }
            }
        }
        return trimmed
    }
}

extension SubscriptionCategory {
    nonisolated static func fromAppStoreGenre(_ genre: String) -> SubscriptionCategory {
        switch genre.lowercased() {
        case "music": .music
        case "entertainment", "sports": .entertainment
        case "photo & video", "graphics & design", "developer tools", "productivity", "business": .productivity
        case "utilities", "navigation": .cloud
        case "news", "magazines & newspapers", "reference": .news
        case "health & fitness": .fitness
        case "shopping", "food & drink": .shopping
        case "education": .education
        case "games": .gaming
        case "finance": .finance
        default: .other
        }
    }
}
