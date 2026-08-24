import Foundation

/// Drops adult and real-money gambling brands from web search results.
/// Users can still type a custom subscription name; this only hides network matches.
nonisolated enum BrandSearchSafety {
    static func allowsQuery(_ query: String) -> Bool {
        !isBlocked(query)
    }

    static func allows(_ hit: BrandSearchHit) -> Bool {
        !isBlocked(hit.name) && !isBlocked(hit.subtitle) && !isBlocked(hit.iconID)
    }

    static func isBlocked(_ raw: String) -> Bool {
        let compact = compact(raw)
        guard compact.count >= 3 else { return false }
        if allowlist.contains(compact) { return false }
        if blockedBrands.contains(where: { compact.contains($0) }) { return true }

        let parts = tokens(raw)
        if parts.contains(where: { blockedTokens.contains($0) }) { return true }

        let host = hostLabels(raw)
        if host.contains(where: { blockedTokens.contains($0) || blockedBrands.contains($0) }) {
            return true
        }
        return false
    }

    private static func compact(_ value: String) -> String {
        value.lowercased().filter(\.isLetter)
    }

    private static func tokens(_ value: String) -> [String] {
        value.lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
    }

    private static func hostLabels(_ value: String) -> [String] {
        let trimmed = value.lowercased()
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
        guard trimmed.contains(".") else { return [] }
        return trimmed
            .split { $0 == "/" || $0 == ":" || $0.isWhitespace }
            .first
            .map { String($0).split(separator: ".").map(String.init) } ?? []
    }

    private static let allowlist: Set<String> = [
        "porsche", "sussex", "essex", "middlesex", "wessex",
        "betterment", "bethesda", "alphabet", "corvette",
    ]

    private static let blockedTokens: Set<String> = [
        "porn", "porno", "xxx", "nsfw", "hentai", "jav",
        "onlyfans", "fansly", "chaturbate", "stripchat",
        "casino", "gambling", "sportsbook", "bookmaker", "wager",
    ]

    private static let blockedBrands: [String] = [
        "pornhub", "xvideos", "xnxx", "xhamster", "youporn", "redtube",
        "spankbang", "brazzers", "realitykings", "bangbros",
        "onlyfans", "fansly", "fancentro", "loyalfans", "manyvids",
        "chaturbate", "stripchat", "cam4", "livejasmin",
        "bet365", "betway", "betfair", "bovada", "draftkings", "fanduel",
        "pokerstars", "williamhill", "paddypower", "leovegas", "casumo",
        "pointsbet", "stakecom", "888casino",
    ]
}
