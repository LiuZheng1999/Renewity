import Foundation

enum SubscriptionManageLinks {
    static let appleSubscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!

    static func parsedURL(from raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let url = URL(string: trimmed), let scheme = url.scheme, !scheme.isEmpty {
            return url
        }
        return URL(string: "https://\(trimmed)")
    }

    static func resolve(userValue: String, iconName: String, name: String) -> URL? {
        if let user = parsedURL(from: userValue) {
            return user
        }
        return suggested(iconName: iconName, name: name)
    }

    static func suggested(iconName: String, name: String) -> URL? {
        let logo = logoID(from: iconName)
        if let url = byLogo[logo] {
            return url
        }
        let folded = name.lowercased()
        return byName.first { folded.contains($0.key) }?.value
    }

    private static func logoID(from iconName: String) -> String {
        if iconName.hasPrefix("logo_") {
            return String(iconName.dropFirst(5))
        }
        return iconName
    }

    private static let byLogo: [String: URL] = [
        "netflix": url("https://www.netflix.com/YourAccount"),
        "disney_plus": url("https://www.disneyplus.com/account"),
        "hulu": url("https://www.hulu.com/account"),
        "max": url("https://www.max.com/account"),
        "prime_video": url("https://www.amazon.com/gp/video/settings"),
        "apple_tv": appleSubscriptionsURL,
        "paramount_plus": url("https://www.paramountplus.com/account/"),
        "youtube": url("https://www.youtube.com/paid_memberships"),
        "youtube_tv": url("https://tv.youtube.com/"),
        "spotify": url("https://www.spotify.com/account/subscription/"),
        "apple_music": appleSubscriptionsURL,
        "youtube_music": url("https://music.youtube.com/"),
        "chatgpt": url("https://chatgpt.com/#settings"),
        "claude": url("https://claude.ai/settings"),
        "cursor": url("https://cursor.com/settings"),
        "notion": url("https://www.notion.so/profile/my-account"),
        "slack": url("https://slack.com/help/articles/218915077"),
        "github": url("https://github.com/settings/billing"),
        "figma": url("https://www.figma.com/settings"),
        "icloud": appleSubscriptionsURL,
        "apple_one": appleSubscriptionsURL,
        "apple_arcade": appleSubscriptionsURL,
        "apple_fitness": appleSubscriptionsURL,
        "xbox_game_pass": url("https://www.xbox.com/en-US/profile/settings"),
        "playstation_plus": url("https://www.playstation.com/en-us/playstation-network/"),
        "nintendo": url("https://accounts.nintendo.com/"),
        "adobe": url("https://account.adobe.com/plans"),
        "microsoft_365": url("https://account.microsoft.com/services"),
        "dropbox": url("https://www.dropbox.com/account/plan"),
        "google_one": url("https://one.google.com/storage"),
        "icloud_plus": appleSubscriptionsURL,
        "nebula": appleSubscriptionsURL,
    ]

    private static let byName: [String: URL] = [
        "netflix": url("https://www.netflix.com/YourAccount"),
        "spotify": url("https://www.spotify.com/account/subscription/"),
        "youtube": url("https://www.youtube.com/paid_memberships"),
        "disney": url("https://www.disneyplus.com/account"),
        "chatgpt": url("https://chatgpt.com/#settings"),
        "openai": url("https://chatgpt.com/#settings"),
        "apple tv": appleSubscriptionsURL,
        "apple music": appleSubscriptionsURL,
        "icloud": appleSubscriptionsURL,
    ]

    private static func url(_ string: String) -> URL {
        URL(string: string)!
    }
}

extension Subscription {
    var resolvedManagementURL: URL? {
        SubscriptionManageLinks.resolve(userValue: managementURL, iconName: iconName, name: name)
    }
}
