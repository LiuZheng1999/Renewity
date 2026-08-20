import Foundation
import UserNotifications

enum ReminderService {
    static var areRemindersEnabled: Bool {
        if UserDefaults.standard.object(forKey: "remindersEnabled") == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: "remindersEnabled")
    }

    static var reminderHour: Int {
        let stored = UserDefaults.standard.object(forKey: "reminderHour") as? Int
        return stored ?? 9
    }

    static func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    static func reschedule(for subscription: Subscription) {
        let plan = ReminderPlan(subscription: subscription)
        let enabled = areRemindersEnabled
        let hour = reminderHour
        Task { await Scheduler.shared.reschedule(plan, enabled: enabled, hour: hour) }
    }

    static func cancel(id: UUID) {
        Task { await Scheduler.shared.cancel(id: id) }
    }

    static func rescheduleAll(_ subscriptions: [Subscription]) {
        let plans = subscriptions.map(ReminderPlan.init)
        let enabled = areRemindersEnabled
        let hour = reminderHour
        Task { await Scheduler.shared.rescheduleAll(plans, enabled: enabled, hour: hour) }
    }
}

private struct ReminderPlan: Sendable {
    let id: UUID
    let name: String
    let priceText: String
    let isActive: Bool
    let isInTrial: Bool
    let trialEndDate: Date?
    let trialOffsets: [Int]
    let reminderOffsets: [Int]
    let billingDate: Date
    let cycle: BillingCycle
    let customValue: Int
    let customUnit: CustomCycleUnit

    @MainActor
    init(subscription: Subscription) {
        id = subscription.id
        name = subscription.name
        priceText = Formatters.currency(subscription.price, code: subscription.resolvedCurrencyCode)
        isActive = subscription.isActive
        isInTrial = subscription.isInTrial
        trialEndDate = subscription.trialEndDate
        trialOffsets = subscription.trialReminderOffsets
        reminderOffsets = subscription.reminderOffsets
        customValue = subscription.customCycleValue
        customUnit = subscription.customCycleUnit
        cycle = subscription.billingCycle

        var billing = subscription.upcomingBillingDate
        if subscription.isInTrial, let trialEndDate {
            billing = subscription.billingCycle.nextDate(
                after: Calendar.current.startOfDay(for: trialEndDate),
                customValue: subscription.customCycleValue,
                customUnit: subscription.customCycleUnit
            )
        }
        billingDate = billing
    }
}

private struct PlannedRequest: Sendable {
    let identifier: String
    let title: String
    let body: String
    let components: DateComponents
    let fireDate: Date
}

private actor Scheduler {
    static let shared = Scheduler()

    private static let maxPending = 60
    private static let maxBillingOccurrences = 12

    func cancel(id: UUID) async {
        await removePending(prefix: id.uuidString)
    }

    func reschedule(_ plan: ReminderPlan, enabled: Bool, hour: Int) async {
        await removePending(prefix: plan.id.uuidString)
        guard enabled, plan.isActive else { return }
        let planned = Self.requests(for: plan, hour: hour)
        await add(planned)
        await trimIfNeeded()
    }

    func rescheduleAll(_ plans: [ReminderPlan], enabled: Bool, hour: Int) async {
        let center = UNUserNotificationCenter.current()
        if !enabled {
            center.removeAllPendingNotificationRequests()
            return
        }

        let existing = await center.pendingNotificationRequests()
        let ours = existing.filter { Self.isManaged($0.identifier) }.map(\.identifier)
        if !ours.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: ours)
        }

        var planned: [PlannedRequest] = []
        for plan in plans where plan.isActive {
            planned.append(contentsOf: Self.requests(for: plan, hour: hour))
        }
        planned.sort { $0.fireDate < $1.fireDate }
        await add(Array(planned.prefix(Self.maxPending)))
    }

    private func add(_ requests: [PlannedRequest]) async {
        let center = UNUserNotificationCenter.current()
        for item in requests {
            let content = UNMutableNotificationContent()
            content.title = item.title
            content.body = item.body
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: item.components, repeats: false)
            let request = UNNotificationRequest(identifier: item.identifier, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    private func trimIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let managed = pending.filter { Self.isManaged($0.identifier) }
        guard managed.count > Self.maxPending else { return }

        let sorted = managed.sorted { lhs, rhs in
            fireDate(of: lhs) < fireDate(of: rhs)
        }
        let extra = sorted.dropFirst(Self.maxPending).map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: Array(extra))
    }

    private func removePending(prefix: String) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        if !ids.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    private func fireDate(of request: UNNotificationRequest) -> Date {
        if let trigger = request.trigger as? UNCalendarNotificationTrigger,
           let date = trigger.nextTriggerDate() {
            return date
        }
        return .distantFuture
    }

    private static func isManaged(_ identifier: String) -> Bool {
        identifier.contains("-d") || identifier.contains("-t")
    }

    private static func requests(for plan: ReminderPlan, hour: Int) -> [PlannedRequest] {
        let calendar = Calendar.current
        var items: [PlannedRequest] = []

        if plan.isInTrial, let trialEndDate = plan.trialEndDate {
            for days in plan.trialOffsets {
                guard let components = oneShotComponents(
                    eventDate: trialEndDate,
                    daysBefore: days,
                    hour: hour,
                    calendar: calendar
                ), let fireDate = calendar.date(from: components) else { continue }
                items.append(
                    PlannedRequest(
                        identifier: "\(plan.id.uuidString)-t\(days)",
                        title: String(localized: "试用即将结束"),
                        body: trialBody(name: plan.name, days: days, price: plan.priceText),
                        components: components,
                        fireDate: fireDate
                    )
                )
            }
        }

        for days in plan.reminderOffsets {
            let occurrences = billingComponents(
                billingDate: plan.billingDate,
                plan: plan,
                daysBefore: days,
                hour: hour,
                calendar: calendar,
                limit: maxBillingOccurrences
            )
            for (index, components) in occurrences.enumerated() {
                guard let fireDate = calendar.date(from: components) else { continue }
                items.append(
                    PlannedRequest(
                        identifier: "\(plan.id.uuidString)-d\(days)-\(index)",
                        title: String(localized: "订阅即将续费"),
                        body: billingBody(name: plan.name, days: days, price: plan.priceText),
                        components: components,
                        fireDate: fireDate
                    )
                )
            }
        }

        return items
    }

    private static func billingBody(name: String, days: Int, price: String) -> String {
        if days == 1 {
            return String(localized: "「\(name)」将于明天续费 \(price)")
        }
        return String(localized: "「\(name)」将于 \(days) 天后续费 \(price)")
    }

    private static func trialBody(name: String, days: Int, price: String) -> String {
        if days == 1 {
            return String(localized: "「\(name)」将于明天结束试用，随后扣费 \(price)")
        }
        return String(localized: "「\(name)」将于 \(days) 天后结束试用，随后扣费 \(price)")
    }

    private static func oneShotComponents(
        eventDate: Date,
        daysBefore: Int,
        hour: Int,
        calendar: Calendar
    ) -> DateComponents? {
        let event = calendar.startOfDay(for: eventDate)
        guard let remindDay = calendar.date(byAdding: .day, value: -daysBefore, to: event) else { return nil }
        var components = calendar.dateComponents([.year, .month, .day], from: remindDay)
        components.hour = hour
        components.minute = 0
        if let triggerDate = calendar.date(from: components), triggerDate > Date() {
            return components
        }
        return nil
    }

    private static func billingComponents(
        billingDate: Date,
        plan: ReminderPlan,
        daysBefore: Int,
        hour: Int,
        calendar: Calendar,
        limit: Int
    ) -> [DateComponents] {
        var billing = calendar.startOfDay(for: billingDate)
        var results: [DateComponents] = []
        for _ in 0..<48 {
            guard results.count < limit else { break }
            guard let remindDay = calendar.date(byAdding: .day, value: -daysBefore, to: billing) else { break }
            var components = calendar.dateComponents([.year, .month, .day], from: remindDay)
            components.hour = hour
            components.minute = 0
            if let triggerDate = calendar.date(from: components), triggerDate > Date() {
                results.append(components)
            }
            let next = plan.cycle.nextDate(
                after: billing,
                calendar: calendar,
                customValue: plan.customValue,
                customUnit: plan.customUnit
            )
            if next <= billing { break }
            billing = next
        }
        return results
    }
}
