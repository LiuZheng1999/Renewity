import Foundation

nonisolated struct SubscriptionTemplate: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let logoID: String
    let category: SubscriptionCategory
    let suggestedPrice: Decimal
    let cycle: BillingCycle
    var artworkURL: URL?
    var remoteIconName: String?
    var subtitle: String?

    var iconName: String { remoteIconName ?? "logo_\(logoID)" }

    var isCustomDraft: Bool { id.hasPrefix("custom:") }

    var searchText: String {
        "\(name) \(category.title) \(logoID.replacingOccurrences(of: "_", with: " ")) \(subtitle ?? "")"
    }

    init(
        name: String,
        logoID: String,
        category: SubscriptionCategory,
        suggestedPrice: Decimal,
        cycle: BillingCycle,
        id: String? = nil,
        artworkURL: URL? = nil,
        remoteIconName: String? = nil,
        subtitle: String? = nil
    ) {
        self.id = id ?? "\(logoID)|\(name)"
        self.name = name
        self.logoID = logoID
        self.category = category
        self.suggestedPrice = suggestedPrice
        self.cycle = cycle
        self.artworkURL = artworkURL
        self.remoteIconName = remoteIconName
        self.subtitle = subtitle
    }

    static func customDraft(name: String) -> SubscriptionTemplate {
        SubscriptionTemplate(
            name: name,
            logoID: "custom",
            category: .other,
            suggestedPrice: 0,
            cycle: .monthly,
            id: "custom:\(name)"
        )
    }

    static let all: [SubscriptionTemplate] = entertainment + music + productivity + cloud + news + fitness + shopping + gaming + education + finance + social

    static let featuredLogoIDs: [String] = [
        "netflix", "spotify", "chatgpt", "cursor", "youtube", "disney_plus",
        "notion", "slack", "github", "apple_tv", "claude", "figma",
    ]

    private static let entertainment: [SubscriptionTemplate] = [
        .init(name: "Netflix", logoID: "netflix", category: .entertainment, suggestedPrice: 15.49, cycle: .monthly),
        .init(name: "Disney+", logoID: "disney_plus", category: .entertainment, suggestedPrice: 13.99, cycle: .monthly),
        .init(name: "Hulu", logoID: "hulu", category: .entertainment, suggestedPrice: 17.99, cycle: .monthly),
        .init(name: "Max", logoID: "max", category: .entertainment, suggestedPrice: 16.99, cycle: .monthly),
        .init(name: "Prime Video", logoID: "prime_video", category: .entertainment, suggestedPrice: 8.99, cycle: .monthly),
        .init(name: "Apple TV+", logoID: "apple_tv", category: .entertainment, suggestedPrice: 9.99, cycle: .monthly),
        .init(name: "Paramount+", logoID: "paramount_plus", category: .entertainment, suggestedPrice: 7.99, cycle: .monthly),
        .init(name: "Peacock", logoID: "peacock", category: .entertainment, suggestedPrice: 7.99, cycle: .monthly),
        .init(name: "YouTube Premium", logoID: "youtube", category: .entertainment, suggestedPrice: 13.99, cycle: .monthly),
        .init(name: "YouTube TV", logoID: "youtube_tv", category: .entertainment, suggestedPrice: 82.99, cycle: .monthly),
        .init(name: "ESPN+", logoID: "espn", category: .entertainment, suggestedPrice: 11.99, cycle: .monthly),
        .init(name: "Crunchyroll", logoID: "crunchyroll", category: .entertainment, suggestedPrice: 7.99, cycle: .monthly),
        .init(name: "discovery+", logoID: "discovery_plus", category: .entertainment, suggestedPrice: 6.99, cycle: .monthly),
        .init(name: "Twitch Turbo", logoID: "twitch", category: .entertainment, suggestedPrice: 8.99, cycle: .monthly),
        .init(name: "Starz", logoID: "starz", category: .entertainment, suggestedPrice: 10.99, cycle: .monthly),
        .init(name: "AMC+", logoID: "amc_plus", category: .entertainment, suggestedPrice: 8.99, cycle: .monthly),
        .init(name: "MUBI", logoID: "mubi", category: .entertainment, suggestedPrice: 14.99, cycle: .monthly),
        .init(name: "Criterion Channel", logoID: "criterion", category: .entertainment, suggestedPrice: 10.99, cycle: .monthly),
        .init(name: "Shudder", logoID: "shudder", category: .entertainment, suggestedPrice: 7.99, cycle: .monthly),
        .init(name: "Nebula", logoID: "nebula", category: .entertainment, suggestedPrice: 6, cycle: .monthly),
        .init(name: "Fubo", logoID: "fubo", category: .entertainment, suggestedPrice: 94.99, cycle: .monthly),
        .init(name: "Sling TV", logoID: "sling", category: .entertainment, suggestedPrice: 40, cycle: .monthly),
        .init(name: "NFL+", logoID: "nfl", category: .entertainment, suggestedPrice: 6.99, cycle: .monthly),
        .init(name: "NBA League Pass", logoID: "nba", category: .entertainment, suggestedPrice: 16.99, cycle: .monthly),
        .init(name: "MLB.TV", logoID: "mlb", category: .entertainment, suggestedPrice: 24.99, cycle: .monthly),
        .init(name: "F1 TV", logoID: "f1tv", category: .entertainment, suggestedPrice: 6.99, cycle: .monthly),
        .init(name: "DAZN", logoID: "dazn", category: .entertainment, suggestedPrice: 19.99, cycle: .monthly),
        .init(name: "Audible", logoID: "audible", category: .entertainment, suggestedPrice: 14.95, cycle: .monthly),
    ]

    private static let music: [SubscriptionTemplate] = [
        .init(name: "Spotify", logoID: "spotify", category: .music, suggestedPrice: 11.99, cycle: .monthly),
        .init(name: "Apple Music", logoID: "apple_music", category: .music, suggestedPrice: 10.99, cycle: .monthly),
        .init(name: "Amazon Music", logoID: "amazon_music", category: .music, suggestedPrice: 10.99, cycle: .monthly),
        .init(name: "YouTube Music", logoID: "youtube_music", category: .music, suggestedPrice: 11.99, cycle: .monthly),
        .init(name: "Tidal", logoID: "tidal", category: .music, suggestedPrice: 10.99, cycle: .monthly),
        .init(name: "Pandora Plus", logoID: "pandora", category: .music, suggestedPrice: 5.99, cycle: .monthly),
        .init(name: "SoundCloud Go+", logoID: "soundcloud", category: .music, suggestedPrice: 9.99, cycle: .monthly),
        .init(name: "SiriusXM", logoID: "siriusxm", category: .music, suggestedPrice: 10.99, cycle: .monthly),
        .init(name: "Deezer", logoID: "deezer", category: .music, suggestedPrice: 10.99, cycle: .monthly),
    ]

    private static let productivity: [SubscriptionTemplate] = [
        .init(name: "ChatGPT Plus", logoID: "chatgpt", category: .productivity, suggestedPrice: 20, cycle: .monthly),
        .init(name: "Cursor Pro", logoID: "cursor", category: .productivity, suggestedPrice: 20, cycle: .monthly),
        .init(name: "Claude Pro", logoID: "claude", category: .productivity, suggestedPrice: 20, cycle: .monthly),
        .init(name: "Gemini Advanced", logoID: "gemini", category: .productivity, suggestedPrice: 19.99, cycle: .monthly),
        .init(name: "Perplexity Pro", logoID: "perplexity", category: .productivity, suggestedPrice: 20, cycle: .monthly),
        .init(name: "Microsoft Copilot Pro", logoID: "copilot", category: .productivity, suggestedPrice: 20, cycle: .monthly),
        .init(name: "Grok", logoID: "grok", category: .productivity, suggestedPrice: 30, cycle: .monthly),
        .init(name: "GitHub Copilot", logoID: "github", category: .productivity, suggestedPrice: 10, cycle: .monthly),
        .init(name: "Notion", logoID: "notion", category: .productivity, suggestedPrice: 10, cycle: .monthly),
        .init(name: "Slack Pro", logoID: "slack", category: .productivity, suggestedPrice: 7.25, cycle: .monthly),
        .init(name: "Zoom Pro", logoID: "zoom", category: .productivity, suggestedPrice: 15.99, cycle: .monthly),
        .init(name: "Microsoft 365", logoID: "microsoft_365", category: .productivity, suggestedPrice: 69.99, cycle: .yearly),
        .init(name: "Google Workspace", logoID: "google_workspace", category: .productivity, suggestedPrice: 7, cycle: .monthly),
        .init(name: "Evernote", logoID: "evernote", category: .productivity, suggestedPrice: 14.99, cycle: .monthly),
        .init(name: "Todoist Pro", logoID: "todoist", category: .productivity, suggestedPrice: 4, cycle: .monthly),
        .init(name: "Trello", logoID: "trello", category: .productivity, suggestedPrice: 5, cycle: .monthly),
        .init(name: "Asana", logoID: "asana", category: .productivity, suggestedPrice: 10.99, cycle: .monthly),
        .init(name: "monday.com", logoID: "monday", category: .productivity, suggestedPrice: 9, cycle: .monthly),
        .init(name: "ClickUp", logoID: "clickup", category: .productivity, suggestedPrice: 7, cycle: .monthly),
        .init(name: "Airtable", logoID: "airtable", category: .productivity, suggestedPrice: 20, cycle: .monthly),
        .init(name: "Linear", logoID: "linear", category: .productivity, suggestedPrice: 8, cycle: .monthly),
        .init(name: "Jira", logoID: "jira", category: .productivity, suggestedPrice: 7.91, cycle: .monthly),
        .init(name: "Confluence", logoID: "confluence", category: .productivity, suggestedPrice: 5.16, cycle: .monthly),
        .init(name: "Grammarly", logoID: "grammarly", category: .productivity, suggestedPrice: 12, cycle: .monthly),
        .init(name: "Obsidian Sync", logoID: "obsidian", category: .productivity, suggestedPrice: 4, cycle: .monthly),
        .init(name: "Craft", logoID: "craft", category: .productivity, suggestedPrice: 5, cycle: .monthly),
        .init(name: "Bear Pro", logoID: "bear", category: .productivity, suggestedPrice: 2.99, cycle: .monthly),
        .init(name: "Goodnotes", logoID: "goodnotes", category: .productivity, suggestedPrice: 9.99, cycle: .yearly),
        .init(name: "Notability", logoID: "notability", category: .productivity, suggestedPrice: 14.99, cycle: .yearly),
        .init(name: "Fantastical", logoID: "fantastical", category: .productivity, suggestedPrice: 6.99, cycle: .monthly),
        .init(name: "OmniFocus", logoID: "omnifocus", category: .productivity, suggestedPrice: 9.99, cycle: .monthly),
        .init(name: "TickTick", logoID: "ticktick", category: .productivity, suggestedPrice: 2.99, cycle: .monthly),
        .init(name: "Spark Mail", logoID: "spark", category: .productivity, suggestedPrice: 4.99, cycle: .monthly),
        .init(name: "Superhuman", logoID: "superhuman", category: .productivity, suggestedPrice: 30, cycle: .monthly),
        .init(name: "Outlook", logoID: "outlook", category: .productivity, suggestedPrice: 6.99, cycle: .monthly),
        .init(name: "Loom", logoID: "loom", category: .productivity, suggestedPrice: 12.5, cycle: .monthly),
        .init(name: "Canva Pro", logoID: "canva", category: .productivity, suggestedPrice: 14.99, cycle: .monthly),
        .init(name: "Figma", logoID: "figma", category: .productivity, suggestedPrice: 12, cycle: .monthly),
        .init(name: "Adobe Creative Cloud", logoID: "adobe", category: .productivity, suggestedPrice: 59.99, cycle: .monthly),
        .init(name: "Adobe Photoshop", logoID: "photoshop", category: .productivity, suggestedPrice: 22.99, cycle: .monthly),
        .init(name: "Adobe Lightroom", logoID: "lightroom", category: .productivity, suggestedPrice: 9.99, cycle: .monthly),
        .init(name: "Adobe Acrobat", logoID: "acrobat", category: .productivity, suggestedPrice: 19.99, cycle: .monthly),
        .init(name: "Final Cut Pro", logoID: "final_cut", category: .productivity, suggestedPrice: 7.99, cycle: .monthly),
        .init(name: "Logic Pro", logoID: "logic_pro", category: .productivity, suggestedPrice: 4.99, cycle: .monthly),
        .init(name: "Descript", logoID: "descript", category: .productivity, suggestedPrice: 15, cycle: .monthly),
        .init(name: "CapCut Pro", logoID: "capcut", category: .productivity, suggestedPrice: 9.99, cycle: .monthly),
        .init(name: "GitHub Pro", logoID: "github", category: .productivity, suggestedPrice: 4, cycle: .monthly),
        .init(name: "GitLab", logoID: "gitlab", category: .productivity, suggestedPrice: 29, cycle: .monthly),
        .init(name: "Sentry", logoID: "sentry", category: .productivity, suggestedPrice: 26, cycle: .monthly),
        .init(name: "Datadog", logoID: "datadog", category: .productivity, suggestedPrice: 15, cycle: .monthly),
        .init(name: "QuickBooks", logoID: "quickbooks", category: .productivity, suggestedPrice: 30, cycle: .monthly),
        .init(name: "YNAB", logoID: "ynab", category: .productivity, suggestedPrice: 14.99, cycle: .monthly),
        .init(name: "Rocket Money", logoID: "rocket_money", category: .productivity, suggestedPrice: 12, cycle: .monthly),
        .init(name: "Shopify", logoID: "shopify", category: .productivity, suggestedPrice: 29, cycle: .monthly),
    ]

    private static let cloud: [SubscriptionTemplate] = [
        .init(name: "iCloud+", logoID: "icloud", category: .cloud, suggestedPrice: 2.99, cycle: .monthly),
        .init(name: "Google One", logoID: "google_one", category: .cloud, suggestedPrice: 9.99, cycle: .monthly),
        .init(name: "Google Drive", logoID: "google_drive", category: .cloud, suggestedPrice: 9.99, cycle: .monthly),
        .init(name: "Dropbox", logoID: "dropbox", category: .cloud, suggestedPrice: 11.99, cycle: .monthly),
        .init(name: "OneDrive", logoID: "onedrive", category: .cloud, suggestedPrice: 6.99, cycle: .monthly),
        .init(name: "Box", logoID: "box", category: .cloud, suggestedPrice: 5, cycle: .monthly),
        .init(name: "Backblaze", logoID: "backblaze", category: .cloud, suggestedPrice: 9, cycle: .monthly),
        .init(name: "1Password", logoID: "onepassword", category: .cloud, suggestedPrice: 2.99, cycle: .monthly),
        .init(name: "Bitwarden", logoID: "bitwarden", category: .cloud, suggestedPrice: 10, cycle: .yearly),
        .init(name: "LastPass", logoID: "lastpass", category: .cloud, suggestedPrice: 3, cycle: .monthly),
        .init(name: "Dashlane", logoID: "dashlane", category: .cloud, suggestedPrice: 4.99, cycle: .monthly),
        .init(name: "NordVPN", logoID: "nordvpn", category: .cloud, suggestedPrice: 12.99, cycle: .monthly),
        .init(name: "ExpressVPN", logoID: "expressvpn", category: .cloud, suggestedPrice: 12.95, cycle: .monthly),
        .init(name: "Surfshark", logoID: "surfshark", category: .cloud, suggestedPrice: 15.45, cycle: .monthly),
        .init(name: "Proton Mail", logoID: "proton_mail", category: .cloud, suggestedPrice: 4.99, cycle: .monthly),
        .init(name: "Proton VPN", logoID: "proton_vpn", category: .cloud, suggestedPrice: 9.99, cycle: .monthly),
        .init(name: "Fastmail", logoID: "fastmail", category: .cloud, suggestedPrice: 5, cycle: .monthly),
        .init(name: "Cloudflare", logoID: "cloudflare", category: .cloud, suggestedPrice: 20, cycle: .monthly),
        .init(name: "DigitalOcean", logoID: "digitalocean", category: .cloud, suggestedPrice: 6, cycle: .monthly),
        .init(name: "AWS", logoID: "aws", category: .cloud, suggestedPrice: 20, cycle: .monthly),
    ]

    private static let news: [SubscriptionTemplate] = [
        .init(name: "The New York Times", logoID: "nytimes", category: .news, suggestedPrice: 17, cycle: .monthly),
        .init(name: "The Wall Street Journal", logoID: "wsj", category: .news, suggestedPrice: 16.99, cycle: .monthly),
        .init(name: "The Washington Post", logoID: "wapo", category: .news, suggestedPrice: 10, cycle: .monthly),
        .init(name: "Apple News+", logoID: "apple_news", category: .news, suggestedPrice: 12.99, cycle: .monthly),
        .init(name: "Medium", logoID: "medium", category: .news, suggestedPrice: 5, cycle: .monthly),
        .init(name: "Substack", logoID: "substack", category: .news, suggestedPrice: 5, cycle: .monthly),
        .init(name: "Bloomberg", logoID: "bloomberg", category: .news, suggestedPrice: 34.99, cycle: .monthly),
        .init(name: "The Economist", logoID: "economist", category: .news, suggestedPrice: 19.99, cycle: .monthly),
        .init(name: "The Athletic", logoID: "athletic", category: .news, suggestedPrice: 10.99, cycle: .monthly),
        .init(name: "The New Yorker", logoID: "newyorker", category: .news, suggestedPrice: 8, cycle: .monthly),
        .init(name: "WIRED", logoID: "wired", category: .news, suggestedPrice: 10, cycle: .monthly),
        .init(name: "The Atlantic", logoID: "atlantic", category: .news, suggestedPrice: 8, cycle: .monthly),
    ]

    private static let fitness: [SubscriptionTemplate] = [
        .init(name: "Peloton App", logoID: "peloton", category: .fitness, suggestedPrice: 12.99, cycle: .monthly),
        .init(name: "Apple Fitness+", logoID: "fitness", category: .fitness, suggestedPrice: 9.99, cycle: .monthly),
        .init(name: "Strava", logoID: "strava", category: .fitness, suggestedPrice: 11.99, cycle: .monthly),
        .init(name: "Calm", logoID: "calm", category: .fitness, suggestedPrice: 14.99, cycle: .monthly),
        .init(name: "Headspace", logoID: "headspace", category: .fitness, suggestedPrice: 12.99, cycle: .monthly),
        .init(name: "MyFitnessPal", logoID: "myfitnesspal", category: .fitness, suggestedPrice: 19.99, cycle: .monthly),
        .init(name: "ClassPass", logoID: "classpass", category: .fitness, suggestedPrice: 49, cycle: .monthly),
        .init(name: "Noom", logoID: "noom", category: .fitness, suggestedPrice: 59, cycle: .monthly),
        .init(name: "WHOOP", logoID: "whoop", category: .fitness, suggestedPrice: 30, cycle: .monthly),
        .init(name: "Oura", logoID: "oura", category: .fitness, suggestedPrice: 5.99, cycle: .monthly),
    ]

    private static let shopping: [SubscriptionTemplate] = [
        .init(name: "Amazon Prime", logoID: "prime", category: .shopping, suggestedPrice: 14.99, cycle: .monthly),
        .init(name: "Walmart+", logoID: "walmart", category: .shopping, suggestedPrice: 12.95, cycle: .monthly),
        .init(name: "Costco", logoID: "costco", category: .shopping, suggestedPrice: 65, cycle: .yearly),
        .init(name: "Instacart+", logoID: "instacart", category: .shopping, suggestedPrice: 9.99, cycle: .monthly),
        .init(name: "DashPass", logoID: "doordash", category: .shopping, suggestedPrice: 9.99, cycle: .monthly),
        .init(name: "Uber One", logoID: "uber", category: .shopping, suggestedPrice: 9.99, cycle: .monthly),
        .init(name: "Uber Eats", logoID: "uber_eats", category: .shopping, suggestedPrice: 9.99, cycle: .monthly),
        .init(name: "Grubhub+", logoID: "grubhub", category: .shopping, suggestedPrice: 9.99, cycle: .monthly),
    ]

    private static let gaming: [SubscriptionTemplate] = [
        .init(name: "Xbox Game Pass Ultimate", logoID: "xbox", category: .gaming, suggestedPrice: 19.99, cycle: .monthly),
        .init(name: "Xbox Game Pass Standard", logoID: "xbox", category: .gaming, suggestedPrice: 14.99, cycle: .monthly),
        .init(name: "Xbox Game Pass PC", logoID: "xbox", category: .gaming, suggestedPrice: 11.99, cycle: .monthly),
        .init(name: "PlayStation Plus", logoID: "playstation", category: .gaming, suggestedPrice: 14.99, cycle: .monthly),
        .init(name: "Nintendo Switch Online", logoID: "nintendo", category: .gaming, suggestedPrice: 3.99, cycle: .monthly),
        .init(name: "Apple Arcade", logoID: "apple_arcade", category: .gaming, suggestedPrice: 6.99, cycle: .monthly),
        .init(name: "EA Play", logoID: "ea_play", category: .gaming, suggestedPrice: 5.99, cycle: .monthly),
        .init(name: "EA Play Pro", logoID: "ea_play", category: .gaming, suggestedPrice: 16.99, cycle: .monthly),
        .init(name: "Ubisoft+", logoID: "ubisoft", category: .gaming, suggestedPrice: 17.99, cycle: .monthly),
        .init(name: "GeForce NOW", logoID: "geforce_now", category: .gaming, suggestedPrice: 9.99, cycle: .monthly),
        .init(name: "Amazon Luna+", logoID: "luna", category: .gaming, suggestedPrice: 9.99, cycle: .monthly),
        .init(name: "Boosteroid", logoID: "boosteroid", category: .gaming, suggestedPrice: 9.99, cycle: .monthly),
        .init(name: "Shadow", logoID: "shadow", category: .gaming, suggestedPrice: 14.99, cycle: .monthly),
        .init(name: "Google Play Pass", logoID: "google_play", category: .gaming, suggestedPrice: 4.99, cycle: .monthly),
        .init(name: "Humble Choice", logoID: "humble", category: .gaming, suggestedPrice: 11.99, cycle: .monthly),
        .init(name: "Discord Nitro", logoID: "discord", category: .gaming, suggestedPrice: 9.99, cycle: .monthly),
        .init(name: "Roblox Premium", logoID: "roblox", category: .gaming, suggestedPrice: 4.99, cycle: .monthly),
    ]

    private static let education: [SubscriptionTemplate] = [
        .init(name: "Duolingo Super", logoID: "duolingo", category: .education, suggestedPrice: 6.99, cycle: .monthly),
        .init(name: "Coursera Plus", logoID: "coursera", category: .education, suggestedPrice: 59, cycle: .monthly),
        .init(name: "MasterClass", logoID: "masterclass", category: .education, suggestedPrice: 10, cycle: .monthly),
        .init(name: "Skillshare", logoID: "skillshare", category: .education, suggestedPrice: 16.99, cycle: .monthly),
        .init(name: "LinkedIn Premium", logoID: "linkedin", category: .education, suggestedPrice: 29.99, cycle: .monthly),
        .init(name: "Brilliant", logoID: "brilliant", category: .education, suggestedPrice: 12.49, cycle: .monthly),
        .init(name: "Babbel", logoID: "babbel", category: .education, suggestedPrice: 13.95, cycle: .monthly),
        .init(name: "Udemy", logoID: "udemy", category: .education, suggestedPrice: 16.58, cycle: .monthly),
        .init(name: "Codecademy", logoID: "codecademy", category: .education, suggestedPrice: 14.99, cycle: .monthly),
    ]

    private static let finance: [SubscriptionTemplate] = [
        .init(name: "TradingView Plus", logoID: "tradingview", category: .finance, suggestedPrice: 14.95, cycle: .monthly),
        .init(name: "Robinhood Gold", logoID: "robinhood", category: .finance, suggestedPrice: 5, cycle: .monthly),
        .init(name: "Yahoo Finance Plus", logoID: "yahoo_finance", category: .finance, suggestedPrice: 6.99, cycle: .monthly),
        .init(name: "Seeking Alpha Premium", logoID: "seeking_alpha", category: .finance, suggestedPrice: 19.99, cycle: .monthly),
        .init(name: "Morningstar Investor", logoID: "morningstar", category: .finance, suggestedPrice: 34.95, cycle: .monthly),
        .init(name: "Koyfin Plus", logoID: "koyfin", category: .finance, suggestedPrice: 39, cycle: .monthly),
        .init(name: "Benzinga Pro", logoID: "benzinga", category: .finance, suggestedPrice: 27, cycle: .monthly),
        .init(name: "Coinbase One", logoID: "coinbase", category: .finance, suggestedPrice: 29.99, cycle: .yearly),
        .init(name: "Glassnode Studio", logoID: "glassnode", category: .finance, suggestedPrice: 29, cycle: .monthly),
        .init(name: "Nansen", logoID: "nansen", category: .finance, suggestedPrice: 99, cycle: .monthly),
        .init(name: "Messari Pro", logoID: "messari", category: .finance, suggestedPrice: 24.99, cycle: .monthly),
        .init(name: "Bloomberg Terminal", logoID: "bloomberg_terminal", category: .finance, suggestedPrice: 2010, cycle: .monthly),
        .init(name: "FactSet", logoID: "factset", category: .finance, suggestedPrice: 12000, cycle: .yearly),
    ]

    private static let social: [SubscriptionTemplate] = [
        .init(name: "X Premium", logoID: "x", category: .other, suggestedPrice: 8, cycle: .monthly),
        .init(name: "Reddit Premium", logoID: "reddit", category: .other, suggestedPrice: 5.99, cycle: .monthly),
        .init(name: "Telegram Premium", logoID: "telegram", category: .other, suggestedPrice: 4.99, cycle: .monthly),
        .init(name: "Snapchat+", logoID: "snapchat", category: .other, suggestedPrice: 3.99, cycle: .monthly),
        .init(name: "Patreon", logoID: "patreon", category: .other, suggestedPrice: 5, cycle: .monthly),
    ]
}
