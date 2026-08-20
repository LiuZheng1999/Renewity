import Foundation

struct WidgetSnapshot: Codable, Equatable {
    var currencyCode: String
    var monthlyTotal: Double
    var yearlyTotal: Double
    var activeCount: Int
    var upcomingCount: Int
    var upcoming: [WidgetUpcomingItem]
    var updatedAt: Date
    var totalsAreApproximate: Bool?

    var isApproximate: Bool { totalsAreApproximate == true }

    static let empty = WidgetSnapshot(
        currencyCode: "CNY",
        monthlyTotal: 0,
        yearlyTotal: 0,
        activeCount: 0,
        upcomingCount: 0,
        upcoming: [],
        updatedAt: .now,
        totalsAreApproximate: false
    )

    static let preview = WidgetSnapshot(
        currencyCode: "CNY",
        monthlyTotal: 248,
        yearlyTotal: 2976,
        activeCount: 5,
        upcomingCount: 3,
        upcoming: [
            WidgetUpcomingItem(id: UUID(), name: "Netflix", price: 15.49, billingDate: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now, colorHex: "E84C3D", currencyCode: "USD"),
            WidgetUpcomingItem(id: UUID(), name: "Spotify", price: 11.99, billingDate: Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now, colorHex: "2EB878", currencyCode: "USD"),
            WidgetUpcomingItem(id: UUID(), name: "ChatGPT Plus", price: 20, billingDate: Calendar.current.date(byAdding: .day, value: 6, to: .now) ?? .now, colorHex: "5E5CE6", currencyCode: "USD"),
            WidgetUpcomingItem(id: UUID(), name: "iCloud+", price: 2.99, billingDate: Calendar.current.date(byAdding: .day, value: 11, to: .now) ?? .now, colorHex: "3399DB", currencyCode: "USD"),
        ],
        updatedAt: .now,
        totalsAreApproximate: true
    )
}

struct WidgetUpcomingItem: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var price: Double
    var billingDate: Date
    var colorHex: String
    var currencyCode: String?

    var resolvedCurrencyCode: String { currencyCode ?? "CNY" }
}

enum WidgetDataStore {
    static let appGroupID = "group.Maoxia-Xiang.Renewity"
    static let storageKey = "widgetSnapshot"

    static func save(_ snapshot: WidgetSnapshot) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(snapshot) {
            defaults.set(data, forKey: storageKey)
        }
    }

    static func load() -> WidgetSnapshot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard
            let defaults = UserDefaults(suiteName: appGroupID),
            let data = defaults.data(forKey: storageKey),
            let snapshot = try? decoder.decode(WidgetSnapshot.self, from: data)
        else {
            return .empty
        }
        return snapshot
    }
}

enum WidgetFormatters {
    private static var locale: Locale { .autoupdatingCurrent }

    static func currency(_ value: Double, code: String, approximate: Bool = false) -> String {
        let formatted = value.formatted(
            .currency(code: code)
                .locale(locale)
                .precision(.fractionLength(0...2))
        )
        if approximate {
            return String(localized: "约 \(formatted)")
        }
        return formatted
    }

    static func billingRelative(_ date: Date) -> String {
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: date)
        ).day ?? 0

        switch days {
        case 0: return String(localized: "今天")
        case 1: return String(localized: "明天")
        default: return String(localized: "\(days) 天后")
        }
    }

    static func monthTitle(_ date: Date = .now) -> String {
        date.formatted(.dateTime.month(.wide).locale(locale))
    }
}
