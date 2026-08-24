import Foundation

enum Formatters {
    private static var locale: Locale { .autoupdatingCurrent }

    static func currency(_ value: Decimal, code: String, approximate: Bool = false) -> String {
        _ = approximate
        let text = value.formatted(
            .currency(code: code)
                .locale(locale)
                .precision(.fractionLength(0...2))
        )
        return simplifiedUSDSymbol(text, code: code)
    }

    static func currencySymbol(for code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.locale = locale
        return simplifiedUSDSymbol(formatter.currencySymbol ?? code, code: code)
    }

    private static func simplifiedUSDSymbol(_ text: String, code: String) -> String {
        guard code.caseInsensitiveCompare("USD") == .orderedSame else { return text }
        return text.replacingOccurrences(of: #"US\s*\$"#, with: "$", options: .regularExpression)
    }

    static func currencyPickerTitle(for code: String) -> String {
        "\(code) (\(currencySymbol(for: code)))"
    }

    static func currencyFullName(for code: String) -> String {
        locale.localizedString(forCurrencyCode: code) ?? code
    }

    static func billingRelative(_ date: Date) -> String {
        relative(date, today: "今天续订", tomorrow: "明天续订", later: { String(localized: "\($0) 天后续订") })
    }

    static func chargeRelative(_ date: Date) -> String {
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: date)
        ).day ?? 0
        if days < 0 { return String(localized: "已付款") }
        return relative(date, today: "今天付款", tomorrow: "明天付款", later: { String(localized: "\($0) 天后付款") })
    }

    static func expiryRelative(_ date: Date) -> String {
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: date)
        ).day ?? 0
        if days < 0 { return String(localized: "已到期") }
        return relative(date, today: "今天到期", tomorrow: "明天到期", later: { String(localized: "\($0) 天后到期") })
    }

    static func trialRelative(_ date: Date) -> String {
        relative(date, today: "今天试用到期", tomorrow: "明天试用到期", later: { String(localized: "\($0) 天后试用到期") })
    }

    static func eventRelative(for subscription: Subscription) -> String {
        if subscription.isInTrial {
            return trialRelative(subscription.nextRelevantDate)
        }
        if !subscription.doesRenew {
            return expiryRelative(subscription.upcomingBillingDate)
        }
        return billingRelative(subscription.upcomingBillingDate)
    }

    private static func relative(
        _ date: Date,
        today: String.LocalizationValue,
        tomorrow: String.LocalizationValue,
        later: (Int) -> String
    ) -> String {
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: date)
        ).day ?? 0

        switch days {
        case 0: return String(localized: today)
        case 1: return String(localized: tomorrow)
        default: return later(days)
        }
    }

    static func mediumDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day().locale(locale))
    }

    static func mediumDateTime(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day().hour().minute().locale(locale))
    }

    static func relativeUpdatedAt(_ date: Date) -> String {
        let calendar = Calendar.current
        let time = date.formatted(.dateTime.hour().minute().locale(locale))
        if calendar.isDateInToday(date) {
            return String(localized: "今天 \(time)")
        }
        if calendar.isDateInYesterday(date) {
            return String(localized: "昨天 \(time)")
        }
        return date.formatted(.dateTime.month(.abbreviated).day().hour().minute().locale(locale))
    }

    static func monthTitle(_ date: Date = .now) -> String {
        date.formatted(.dateTime.month(.wide).locale(locale))
    }

    static func weekdayShort(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.narrow).locale(locale))
    }
}
