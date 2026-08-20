import Foundation
import SwiftData
import WidgetKit

enum WidgetSync {
    static func refresh(
        subscriptions: [Subscription],
        categories: [AppCategory],
        currencyCode: String,
        exchangeRates: ExchangeRateStore
    ) {
        let monthly = subscriptions.convertedMonthlySpend(to: currencyCode, using: exchangeRates)
        let upcoming = subscriptions.upcoming(withinDays: 14)
        let approximate = subscriptions.needsCurrencyConversion(to: currencyCode) || monthly.hasFailures
        let snapshot = WidgetSnapshot(
            currencyCode: currencyCode,
            monthlyTotal: NSDecimalNumber(decimal: monthly.amount).doubleValue,
            yearlyTotal: NSDecimalNumber(decimal: monthly.amount * 12).doubleValue,
            activeCount: subscriptions.active.count,
            upcomingCount: upcoming.count,
            upcoming: upcoming.prefix(5).map { subscription in
                WidgetUpcomingItem(
                    id: subscription.id,
                    name: subscription.name,
                    price: NSDecimalNumber(decimal: subscription.price).doubleValue,
                    billingDate: subscription.nextRelevantDate,
                    colorHex: subscription.resolvedCategory(in: categories).colorHex,
                    currencyCode: subscription.resolvedCurrencyCode
                )
            },
            updatedAt: .now,
            totalsAreApproximate: approximate
        )
        WidgetDataStore.save(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
