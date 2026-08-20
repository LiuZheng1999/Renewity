import Foundation
import SwiftData
import SwiftUI

nonisolated enum BillingCycle: String, Codable, CaseIterable, Identifiable, Sendable {
    case weekly
    case biweekly
    case monthly
    case quarterly
    case semiannually
    case yearly
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weekly: String(localized: "每周")
        case .biweekly: String(localized: "每两周")
        case .monthly: String(localized: "每月")
        case .quarterly: String(localized: "每季")
        case .semiannually: String(localized: "每半年")
        case .yearly: String(localized: "每年")
        case .custom: String(localized: "自定义")
        }
    }

    var shortTitle: String {
        switch self {
        case .weekly: String(localized: "周")
        case .biweekly: String(localized: "两周")
        case .monthly: String(localized: "月")
        case .quarterly: String(localized: "季")
        case .semiannually: String(localized: "半年")
        case .yearly: String(localized: "年")
        case .custom: String(localized: "自定义")
        }
    }

    func nextDate(
        after date: Date,
        calendar: Calendar = .current,
        customValue: Int = 1,
        customUnit: CustomCycleUnit = .month
    ) -> Date {
        shiftedDate(from: date, steps: 1, calendar: calendar, customValue: customValue, customUnit: customUnit)
    }

    func previousDate(
        before date: Date,
        calendar: Calendar = .current,
        customValue: Int = 1,
        customUnit: CustomCycleUnit = .month
    ) -> Date {
        shiftedDate(from: date, steps: -1, calendar: calendar, customValue: customValue, customUnit: customUnit)
    }

    func upcomingDate(
        from date: Date,
        calendar: Calendar = .current,
        now: Date = .now,
        customValue: Int = 1,
        customUnit: CustomCycleUnit = .month
    ) -> Date {
        let today = calendar.startOfDay(for: now)
        var result = calendar.startOfDay(for: date)
        while result < today {
            result = nextDate(after: result, calendar: calendar, customValue: customValue, customUnit: customUnit)
        }
        return result
    }

    func nextBillingDate(
        afterLastCharge lastCharge: Date,
        calendar: Calendar = .current,
        now: Date = .now,
        customValue: Int = 1,
        customUnit: CustomCycleUnit = .month
    ) -> Date {
        let today = calendar.startOfDay(for: now)
        var date = calendar.startOfDay(for: lastCharge)
        if date <= today {
            date = nextDate(after: date, calendar: calendar, customValue: customValue, customUnit: customUnit)
        }
        return upcomingDate(from: date, calendar: calendar, now: now, customValue: customValue, customUnit: customUnit)
    }

    func shiftedDate(
        from date: Date,
        steps: Int,
        calendar: Calendar,
        customValue: Int = 1,
        customUnit: CustomCycleUnit = .month
    ) -> Date {
        let value = max(1, customValue)
        switch self {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: steps, to: date) ?? date
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: steps * 2, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: steps, to: date) ?? date
        case .quarterly:
            return calendar.date(byAdding: .month, value: steps * 3, to: date) ?? date
        case .semiannually:
            return calendar.date(byAdding: .month, value: steps * 6, to: date) ?? date
        case .yearly:
            return calendar.date(byAdding: .year, value: steps, to: date) ?? date
        case .custom:
            switch customUnit {
            case .day:
                return calendar.date(byAdding: .day, value: steps * value, to: date) ?? date
            case .week:
                return calendar.date(byAdding: .weekOfYear, value: steps * value, to: date) ?? date
            case .month:
                return calendar.date(byAdding: .month, value: steps * value, to: date) ?? date
            case .year:
                return calendar.date(byAdding: .year, value: steps * value, to: date) ?? date
            }
        }
    }
}

nonisolated enum CustomCycleUnit: String, Codable, CaseIterable, Identifiable, Sendable {
    case day
    case week
    case month
    case year

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day: String(localized: "天")
        case .week: String(localized: "周")
        case .month: String(localized: "月")
        case .year: String(localized: "年")
        }
    }
}

enum BillingDateKind: String, CaseIterable, Identifiable {
    case next
    case last

    var id: String { rawValue }

    var title: String {
        switch self {
        case .next: String(localized: "下次扣费")
        case .last: String(localized: "最近扣费")
        }
    }
}

nonisolated enum SubscriptionCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case entertainment
    case music
    case productivity
    case cloud
    case news
    case fitness
    case shopping
    case education
    case gaming
    case finance
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .entertainment: String(localized: "娱乐")
        case .music: String(localized: "音乐")
        case .productivity: String(localized: "效率")
        case .cloud: String(localized: "云服务")
        case .news: String(localized: "资讯")
        case .fitness: String(localized: "健康")
        case .shopping: String(localized: "购物")
        case .education: String(localized: "学习")
        case .gaming: String(localized: "游戏")
        case .finance: String(localized: "金融")
        case .other: String(localized: "其他")
        }
    }

    var icon: String {
        switch self {
        case .entertainment: "play.tv.fill"
        case .music: "music.note"
        case .productivity: "laptopcomputer"
        case .cloud: "cloud.fill"
        case .news: "newspaper.fill"
        case .fitness: "figure.run"
        case .shopping: "cart.fill"
        case .education: "book.fill"
        case .gaming: "gamecontroller.fill"
        case .finance: "chart.line.uptrend.xyaxis"
        case .other: "square.grid.2x2.fill"
        }
    }

    var color: Color {
        switch self {
        case .entertainment: Color(red: 0.91, green: 0.30, blue: 0.24)
        case .music: Color(red: 0.18, green: 0.72, blue: 0.47)
        case .productivity: Color(red: 0.37, green: 0.36, blue: 0.90)
        case .cloud: Color(red: 0.20, green: 0.60, blue: 0.86)
        case .news: Color(red: 0.95, green: 0.61, blue: 0.07)
        case .fitness: Color(red: 0.95, green: 0.45, blue: 0.17)
        case .shopping: Color(red: 0.61, green: 0.35, blue: 0.71)
        case .education: Color(red: 0.15, green: 0.68, blue: 0.63)
        case .gaming: Color(red: 0.22, green: 0.32, blue: 0.93)
        case .finance: Color(red: 0.12, green: 0.56, blue: 0.36)
        case .other: Color(red: 0.47, green: 0.52, blue: 0.56)
        }
    }

    var hex: String {
        switch self {
        case .entertainment: "E84C3D"
        case .music: "2EB878"
        case .productivity: "5E5CE6"
        case .cloud: "3399DB"
        case .news: "F29B12"
        case .fitness: "F2732B"
        case .shopping: "9B59B6"
        case .education: "26AD9F"
        case .gaming: "3852ED"
        case .finance: "1E8E5A"
        case .other: "78858F"
        }
    }
}

struct CategoryTotal: Identifiable {
    var id: String { category.identifier }
    let category: AppCategory
    let amount: Decimal
}

struct CurrencyConversionResult {
    var amount: Decimal
    var convertedCount: Int
    var failedCount: Int

    var hasFailures: Bool { failedCount > 0 }
}

nonisolated enum PaymentMethod: String, Codable, CaseIterable, Identifiable, Sendable {
    case applePay
    case googlePay
    case paypal
    case visa
    case mastercard
    case amex
    case creditCard
    case debitCard
    case bankTransfer
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .applePay: String(localized: "Apple Pay")
        case .googlePay: String(localized: "Google Pay")
        case .paypal: String(localized: "PayPal")
        case .visa: String(localized: "Visa")
        case .mastercard: String(localized: "Mastercard")
        case .amex: String(localized: "American Express")
        case .creditCard: String(localized: "信用卡")
        case .debitCard: String(localized: "借记卡")
        case .bankTransfer: String(localized: "银行转账")
        case .other: String(localized: "其他")
        }
    }

    var artworkName: String? {
        switch self {
        case .applePay: "pay_applepay"
        case .googlePay: "pay_googlepay"
        case .paypal: "pay_paypal"
        case .visa: "pay_visa"
        case .mastercard: "pay_mastercard"
        case .amex: "pay_amex"
        case .creditCard, .debitCard, .bankTransfer, .other: nil
        }
    }

    static func normalizedID(_ raw: String) -> String {
        switch raw {
        case "alipay", "wechatPay", "unionPay", "unionpay":
            other.rawValue
        default:
            raw.isEmpty ? creditCard.rawValue : raw
        }
    }
}

@Model
final class Subscription {
    var id: UUID = UUID()
    var name: String = ""
    var price: Decimal = 0
    var currencyCode: String = "CNY"
    var billingCycleRaw: String = BillingCycle.monthly.rawValue
    var categoryRaw: String = SubscriptionCategory.other.rawValue
    var nextBillingDate: Date = Date()
    var notes: String = ""
    var isActive: Bool = true
    var iconName: String = "creditcard.fill"
    var paymentMethodRaw: String = PaymentMethod.creditCard.rawValue
    var customCycleValue: Int = 1
    var customCycleUnitRaw: String = CustomCycleUnit.month.rawValue
    var accentColorHex: String = ""
    var remindBeforeBilling: Bool = false
    var reminderOffsetsRaw: String = ""
    var trialEndDate: Date? = nil
    var trialReminderOffsetsRaw: String = ""
    var createdAt: Date = Date()

    var billingCycle: BillingCycle {
        get { BillingCycle(rawValue: billingCycleRaw) ?? .monthly }
        set { billingCycleRaw = newValue.rawValue }
    }

    var category: SubscriptionCategory {
        get { SubscriptionCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var paymentMethod: PaymentMethod {
        get { PaymentMethod(rawValue: PaymentMethod.normalizedID(paymentMethodRaw)) ?? .other }
        set { paymentMethodRaw = newValue.rawValue }
    }

    var customCycleUnit: CustomCycleUnit {
        get { CustomCycleUnit(rawValue: customCycleUnitRaw) ?? .month }
        set { customCycleUnitRaw = newValue.rawValue }
    }

    var accentColor: Color? {
        accentColorHex.isEmpty ? nil : Color(hex: accentColorHex)
    }

    var resolvedCurrencyCode: String {
        let code = currencyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return code.isEmpty ? "CNY" : code
    }

    func applyBillingCurrency(_ code: String) {
        currencyCode = Self.normalizedCurrencyCode(code)
    }

    static func normalizedCurrencyCode(_ code: String?) -> String {
        let trimmed = code?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() ?? ""
        return trimmed.isEmpty ? "CNY" : trimmed
    }

    var monthlyCost: Decimal {
        let count = Decimal(max(1, customCycleValue))
        switch billingCycle {
        case .weekly:
            return price * 52 / 12
        case .biweekly:
            return price * 26 / 12
        case .monthly:
            return price
        case .quarterly:
            return price / 3
        case .semiannually:
            return price / 6
        case .yearly:
            return price / 12
        case .custom:
            switch customCycleUnit {
            case .day:
                return price * Decimal(365.25 / 12) / count
            case .week:
                return price * 52 / 12 / count
            case .month:
                return price / count
            case .year:
                return price / (12 * count)
            }
        }
    }

    var yearlyCost: Decimal {
        monthlyCost * 12
    }

    var cycleDisplayTitle: String {
        if billingCycle == .custom {
            return String(localized: "每 \(max(1, customCycleValue)) \(customCycleUnit.title)")
        }
        return billingCycle.title
    }

    var upcomingBillingDate: Date {
        if isInTrial, let trialEndDate {
            return Calendar.current.startOfDay(for: trialEndDate)
        }
        return billingCycle.upcomingDate(
            from: nextBillingDate,
            customValue: customCycleValue,
            customUnit: customCycleUnit
        )
    }

    func advancedBillingDate(from date: Date, steps: Int = 1, calendar: Calendar = .current) -> Date {
        billingCycle.shiftedDate(
            from: date,
            steps: steps,
            calendar: calendar,
            customValue: customCycleValue,
            customUnit: customCycleUnit
        )
    }

    func chargeDates(inMonthOf month: Date, calendar: Calendar = .current) -> [Date] {
        guard isActive else { return [] }
        guard let interval = calendar.dateInterval(of: .month, for: month) else { return [] }
        let monthStart = calendar.startOfDay(for: interval.start)
        let monthEnd = interval.end
        let earliest = trialEndDate.map { calendar.startOfDay(for: $0) }
        let anchor = calendar.startOfDay(for: upcomingBillingDate)

        var dates: [Date] = []
        var seen = Set<TimeInterval>()

        func appendIfInMonth(_ date: Date) {
            let day = calendar.startOfDay(for: date)
            guard day >= monthStart, day < monthEnd else { return }
            if let earliest, day < earliest { return }
            if seen.insert(day.timeIntervalSinceReferenceDate).inserted {
                dates.append(day)
            }
        }

        var forward = anchor
        for _ in 0..<400 {
            if forward >= monthEnd { break }
            appendIfInMonth(forward)
            let next = advancedBillingDate(from: forward, steps: 1, calendar: calendar)
            if next <= forward { break }
            forward = next
        }

        var backward = advancedBillingDate(from: anchor, steps: -1, calendar: calendar)
        for _ in 0..<400 {
            if backward < monthStart { break }
            if let earliest, backward < earliest { break }
            appendIfInMonth(backward)
            let previous = advancedBillingDate(from: backward, steps: -1, calendar: calendar)
            if previous >= backward { break }
            backward = previous
        }

        return dates.sorted()
    }

    var daysUntilNextBilling: Int {
        daysUntil(upcomingBillingDate)
    }

    var isInTrial: Bool {
        guard let trialEndDate else { return false }
        return Calendar.current.startOfDay(for: trialEndDate) >= Calendar.current.startOfDay(for: Date())
    }

    /// 试用尚未到期（不含到期当天）。到期当日起按已开始扣费计入开支。
    var isAwaitingFirstCharge: Bool {
        guard let trialEndDate else { return false }
        return Calendar.current.startOfDay(for: trialEndDate) > Calendar.current.startOfDay(for: Date())
    }

    var nextRelevantDate: Date {
        if isInTrial, let trialEndDate {
            return Calendar.current.startOfDay(for: trialEndDate)
        }
        return upcomingBillingDate
    }

    var daysUntilNextEvent: Int {
        daysUntil(nextRelevantDate)
    }

    var isDueSoon: Bool {
        isActive && (0...7).contains(daysUntilNextEvent)
    }

    var reminderOffsets: [Int] {
        get { Self.decodeReminderOffsets(reminderOffsetsRaw, enabled: remindBeforeBilling) }
        set { applyReminderOffsets(newValue) }
    }

    var reminderSummary: String {
        Self.summary(for: reminderOffsets)
    }

    var trialReminderOffsets: [Int] {
        get { Self.decodeStoredOffsets(trialReminderOffsetsRaw) }
        set { applyTrialReminderOffsets(newValue) }
    }

    var trialReminderSummary: String {
        Self.summary(for: trialReminderOffsets)
    }

    func applyReminderOffsets(_ offsets: [Int]) {
        let cleaned = Self.normalizedReminderOffsets(offsets)
        reminderOffsetsRaw = cleaned.map(String.init).joined(separator: ",")
        remindBeforeBilling = !cleaned.isEmpty
    }

    func applyTrialReminderOffsets(_ offsets: [Int]) {
        trialReminderOffsetsRaw = Self.normalizedReminderOffsets(offsets).map(String.init).joined(separator: ",")
    }

    func clearTrial() {
        trialEndDate = nil
        trialReminderOffsetsRaw = ""
    }

    private func daysUntil(_ date: Date) -> Int {
        let calendar = Calendar.current
        return calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: date)
        ).day ?? 0
    }

    static func decodeReminderOffsets(_ raw: String, enabled: Bool) -> [Int] {
        if raw.isEmpty { return enabled ? [1] : [] }
        return decodeStoredOffsets(raw)
    }

    static func decodeStoredOffsets(_ raw: String) -> [Int] {
        if raw.isEmpty { return [] }
        return normalizedReminderOffsets(raw.split(separator: ",").compactMap { Int($0) })
    }

    static func normalizedReminderOffsets(_ offsets: [Int]) -> [Int] {
        Array(Set(offsets.filter { $0 >= 1 && $0 <= 365 })).sorted()
    }

    static func summary(for offsets: [Int]) -> String {
        if offsets.isEmpty { return String(localized: "关闭") }
        return ListFormatter.localizedString(byJoining: offsets.map { ReminderLead.title(for: $0) })
    }

    init(
        name: String,
        price: Decimal,
        currencyCode: String = "CNY",
        billingCycle: BillingCycle = .monthly,
        category: SubscriptionCategory = .other,
        nextBillingDate: Date = .now,
        notes: String = "",
        isActive: Bool = true,
        iconName: String = "creditcard.fill",
        paymentMethod: PaymentMethod = .creditCard,
        customCycleValue: Int = 1,
        customCycleUnit: CustomCycleUnit = .month,
        accentColorHex: String = "",
        remindBeforeBilling: Bool = false,
        reminderOffsets: [Int]? = nil,
        trialEndDate: Date? = nil,
        trialReminderOffsets: [Int]? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.price = price
        self.currencyCode = Self.normalizedCurrencyCode(currencyCode)
        self.billingCycleRaw = billingCycle.rawValue
        self.categoryRaw = category.rawValue
        self.nextBillingDate = nextBillingDate
        self.notes = notes
        self.isActive = isActive
        self.iconName = iconName
        self.paymentMethodRaw = paymentMethod.rawValue
        self.customCycleValue = max(1, customCycleValue)
        self.customCycleUnitRaw = customCycleUnit.rawValue
        self.accentColorHex = accentColorHex
        self.createdAt = Date()
        self.trialEndDate = trialEndDate
        if let reminderOffsets {
            applyReminderOffsets(reminderOffsets)
        } else {
            self.remindBeforeBilling = remindBeforeBilling
            self.reminderOffsetsRaw = remindBeforeBilling ? "1" : ""
        }
        if trialEndDate != nil {
            applyTrialReminderOffsets(trialReminderOffsets ?? [1])
        }
    }
}

nonisolated enum ReminderLead: Hashable, Identifiable, Sendable {
    case days(Int)
    case week
    case custom

    static let presets: [ReminderLead] = [.days(1), .days(3), .days(5), .week, .custom]
    static let maxCount = 3
    static let freeCount = 1

    var id: String {
        switch self {
        case .days(let value): "days-\(value)"
        case .week: "week"
        case .custom: "custom"
        }
    }

    static func matching(_ days: Int) -> ReminderLead {
        switch days {
        case 1: .days(1)
        case 3: .days(3)
        case 5: .days(5)
        case 7: .week
        default: .custom
        }
    }

    var presetDays: Int? {
        switch self {
        case .days(let value): value
        case .week: 7
        case .custom: nil
        }
    }

    var title: String {
        switch self {
        case .days(let value): Self.title(for: value)
        case .week: String(localized: "提前一周")
        case .custom: String(localized: "自定义")
        }
    }

    static func title(for days: Int) -> String {
        if days == 7 { return String(localized: "提前一周") }
        if days == 1 { return String(localized: "提前 1 天") }
        return String(localized: "提前 \(days) 天")
    }

    static func nextUnused(from existing: [Int]) -> Int {
        let used = Set(existing)
        return [1, 3, 5, 7].first { !used.contains($0) } ?? min((existing.max() ?? 1) + 1, 365)
    }
}

extension [Subscription] {
    var active: [Subscription] {
        filter(\.isActive)
    }

    var currentlyPaying: [Subscription] {
        active.filter { !$0.isAwaitingFirstCharge }
    }

    func needsCurrencyConversion(to displayCode: String) -> Bool {
        let display = displayCode.uppercased()
        return currentlyPaying.contains { $0.resolvedCurrencyCode != display }
    }

    func convertedMonthlySpend(to displayCode: String, using rates: ExchangeRateStore) -> CurrencyConversionResult {
        currentlyPaying.reduce(into: CurrencyConversionResult(amount: 0, convertedCount: 0, failedCount: 0)) { result, item in
            if let value = rates.convertedMonthlyCost(of: item, to: displayCode) {
                result.amount += value
                result.convertedCount += 1
            } else {
                result.failedCount += 1
            }
        }
    }

    func convertedYearlySpend(to displayCode: String, using rates: ExchangeRateStore) -> CurrencyConversionResult {
        let monthly = convertedMonthlySpend(to: displayCode, using: rates)
        return CurrencyConversionResult(
            amount: monthly.amount * 12,
            convertedCount: monthly.convertedCount,
            failedCount: monthly.failedCount
        )
    }

    func upcoming(withinDays days: Int) -> [Subscription] {
        active
            .filter { $0.daysUntilNextEvent <= days }
            .sorted { $0.nextRelevantDate < $1.nextRelevantDate }
    }

    func convertedCategoryTotals(
        using categories: [AppCategory],
        displayCode: String,
        rates: ExchangeRateStore
    ) -> [CategoryTotal] {
        Dictionary(grouping: currentlyPaying, by: \.categoryRaw)
            .compactMap { id, items in
                var amount: Decimal = 0
                var didConvert = false
                for item in items {
                    guard let value = rates.convertedMonthlyCost(of: item, to: displayCode) else { continue }
                    amount += value
                    didConvert = true
                }
                guard didConvert else { return nil }
                return CategoryTotal(
                    category: AppCategory.resolve(id, in: categories),
                    amount: amount
                )
            }
            .sorted { $0.amount > $1.amount }
    }
}

enum BillingCurrencyMigration {
    static let flagKey = "didMigrateBillingCurrency"

    static func migrateIfNeeded(in context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: flagKey) else { return }
        let display = UserDefaults.standard.string(forKey: "currencyCode") ?? "CNY"
        let items = (try? context.fetch(FetchDescriptor<Subscription>())) ?? []
        for item in items {
            item.currencyCode = display
        }
        try? context.save()
        UserDefaults.standard.set(true, forKey: flagKey)
    }
}
