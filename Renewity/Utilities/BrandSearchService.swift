import Foundation

nonisolated struct BrandSearchHit: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let subtitle: String
    let artworkURLs: [URL]
    let category: SubscriptionCategory
    let iconID: String
    var bundledIconName: String
    var suggestedPrice: Decimal
    var cycle: BillingCycle
    var isCatalog: Bool

    var previewURL: URL? { artworkURLs.first }

    init(
        id: String,
        name: String,
        subtitle: String,
        artworkURLs: [URL],
        category: SubscriptionCategory,
        iconID: String,
        bundledIconName: String = "",
        suggestedPrice: Decimal = 0,
        cycle: BillingCycle = .monthly,
        isCatalog: Bool = false
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.artworkURLs = artworkURLs
        self.category = category
        self.iconID = iconID
        self.bundledIconName = bundledIconName
        self.suggestedPrice = suggestedPrice
        self.cycle = cycle
        self.isCatalog = isCatalog
    }

    func template(remoteIconName: String?) -> SubscriptionTemplate {
        SubscriptionTemplate(
            name: name,
            logoID: isCatalog ? iconID : "web",
            category: category,
            suggestedPrice: suggestedPrice,
            cycle: cycle,
            id: id,
            artworkURL: previewURL,
            remoteIconName: remoteIconName ?? (bundledIconName.hasPrefix("logo_") ? nil : bundledIconName),
            subtitle: subtitle
        )
    }
}

nonisolated enum BrandSearchService {
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 8
        configuration.timeoutIntervalForResource = 12
        return URLSession(configuration: configuration)
    }()

    static func searchWeb(_ query: String) async -> [BrandSearchHit] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }

        async let companies = companyHits(for: trimmed)
        async let apps = appHits(for: trimmed)
        return merge(await companies, await apps)
    }

    private static func companyHits(for query: String) async -> [BrandSearchHit] {
        var hits = (try? await clearbitCompanies(for: query)) ?? []
        if looksLikeDomain(query) {
            hits.insert(domainHit(query), at: 0)
        }
        return hits
    }

    private static func appHits(for query: String) async -> [BrandSearchHit] {
        let apps = (try? await AppStoreSearchService.search(query)) ?? []
        return apps.map { app in
            BrandSearchHit(
                id: "appstore:\(app.id)",
                name: app.name,
                subtitle: app.seller,
                artworkURLs: [app.artworkURL],
                category: app.category,
                iconID: String(app.id)
            )
        }
    }

    private static func clearbitCompanies(for query: String) async throws -> [BrandSearchHit] {
        var components = URLComponents(string: "https://autocomplete.clearbit.com/v1/companies/suggest")!
        components.queryItems = [URLQueryItem(name: "query", value: query)]
        guard let url = components.url else { return [] }

        let (data, _) = try await session.data(from: url)
        let companies = try JSONDecoder().decode([ClearbitCompany].self, from: data)
        let ranked = companies.sorted { score($0, query: query) > score($1, query: query) }

        var uniqueNames = Set<String>()
        var hits: [BrandSearchHit] = []
        for company in ranked.prefix(12) {
            let key = normalize(company.name)
            guard uniqueNames.insert(key).inserted, !company.domain.isEmpty else { continue }
            hits.append(
                BrandSearchHit(
                    id: "web:\(company.domain)",
                    name: company.name,
                    subtitle: company.domain,
                    artworkURLs: logoURLs(for: company.domain),
                    category: SubscriptionCategory.guess(from: company.name, domain: company.domain),
                    iconID: "web.\(company.domain)"
                )
            )
        }
        return hits
    }

    private static func domainHit(_ query: String) -> BrandSearchHit {
        let domain = query.lowercased().replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let name = domain.split(separator: ".").first.map { String($0).capitalized } ?? query
        return BrandSearchHit(
            id: "web:\(domain)",
            name: name,
            subtitle: domain,
            artworkURLs: logoURLs(for: domain),
            category: SubscriptionCategory.guess(from: name, domain: domain),
            iconID: "web.\(domain)"
        )
    }

    private static func logoURLs(for domain: String) -> [URL] {
        [
            URL(string: "https://icon.horse/icon/\(domain)"),
            URL(string: "https://unavatar.io/\(domain)"),
            URL(string: "https://favicone.com/\(domain)?s=256"),
        ].compactMap { $0 }
    }

    private static func looksLikeDomain(_ query: String) -> Bool {
        let value = query.lowercased()
        guard !value.contains(" "), value.contains("."), value.count >= 4 else { return false }
        return value.split(separator: ".").count >= 2
    }

    private static func score(_ company: ClearbitCompany, query: String) -> Int {
        let q = query.lowercased()
        let name = company.name.lowercased()
        let domain = company.domain.lowercased()
        if name == q { return 100 }
        if domain == q || domain.hasPrefix(q + ".") { return 90 }
        if name.hasPrefix(q) { return 80 }
        if domain.hasPrefix(q) { return 70 }
        if name.contains(q) { return 50 }
        if domain.contains(q) { return 30 }
        return 10
    }

    private static func merge(_ companies: [BrandSearchHit], _ apps: [BrandSearchHit]) -> [BrandSearchHit] {
        var appByName: [String: BrandSearchHit] = [:]
        for app in apps {
            let key = normalize(app.name)
            if appByName[key] == nil {
                appByName[key] = app
            }
        }

        var seen = Set<String>()
        var unique: [BrandSearchHit] = []

        for company in companies {
            let key = normalize(company.name)
            guard seen.insert(key).inserted else { continue }
            if let app = appByName[key] {
                unique.append(
                    BrandSearchHit(
                        id: company.id,
                        name: company.name,
                        subtitle: company.subtitle,
                        artworkURLs: app.artworkURLs + company.artworkURLs,
                        category: company.category == .other ? app.category : company.category,
                        iconID: app.iconID
                    )
                )
            } else {
                unique.append(company)
            }
        }

        for app in apps {
            let key = normalize(app.name)
            guard seen.insert(key).inserted else { continue }
            unique.append(app)
        }

        return Array(unique.prefix(24))
    }

    private static func normalize(_ value: String) -> String {
        value.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: ".", with: "")
    }
}

nonisolated private struct ClearbitCompany: Decodable, Sendable {
    var name: String
    var domain: String
}

extension SubscriptionCategory {
    nonisolated static func guess(from name: String, domain: String) -> SubscriptionCategory {
        let text = "\(name) \(domain)".lowercased()
        let rules: [(SubscriptionCategory, [String])] = [
            (.entertainment, ["netflix", "disney", "hulu", "hbo", "max.com", "youtube", "twitch", "paramount", "peacock", "crunchyroll", "starz"]),
            (.music, ["spotify", "tidal", "pandora", "deezer", "soundcloud", "apple music", "sirius"]),
            (.productivity, ["notion", "slack", "figma", "adobe", "microsoft", "google workspace", "openai", "chatgpt", "anthropic", "claude", "cursor", "github", "zoom", "canva"]),
            (.cloud, ["icloud", "dropbox", "box.com", "onedrive", "aws", "cloudflare", "digitalocean", "nordvpn", "expressvpn", "1password"]),
            (.news, ["nytimes", "new york times", "wsj", "washingtonpost", "economist", "bloomberg", "medium", "substack", "wired", "atlantic"]),
            (.fitness, ["peloton", "strava", "calm", "headspace", "myfitnesspal", "classpass", "whoop", "oura"]),
            (.shopping, ["amazon", "walmart", "costco", "instacart", "doordash", "uber", "grubhub"]),
            (.education, ["duolingo", "coursera", "masterclass", "skillshare", "udemy", "codecademy", "brilliant"]),
            (.gaming, ["xbox", "playstation", "nintendo", "steam", "roblox", "discord", "ea.com", "ubisoft"]),
            (.finance, ["tradingview", "robinhood", "coinbase", "yahoo finance", "morningstar"]),
        ]
        for (category, keywords) in rules where keywords.contains(where: { text.contains($0) }) {
            return category
        }
        return .other
    }
}
