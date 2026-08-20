import Foundation
import SwiftData

enum PreviewContainer {
    @MainActor
    static var sample: ModelContainer = {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try! ModelContainer(
            for: Subscription.self,
            AppCategory.self,
            AppPaymentMethod.self,
            configurations: configuration
        )
        AppCategory.seedBuiltIns(in: container.mainContext)
        AppPaymentMethod.seedBuiltIns(in: container.mainContext)
        let calendar = Calendar.current
        let now = Date()

        let samples: [Subscription] = [
            Subscription(
                name: "Netflix",
                price: 15.49,
                currencyCode: "USD",
                billingCycle: .monthly,
                category: .entertainment,
                nextBillingDate: calendar.date(byAdding: .day, value: 2, to: now) ?? now,
                iconName: "logo_netflix"
            ),
            Subscription(
                name: "Spotify",
                price: 11.99,
                currencyCode: "USD",
                billingCycle: .monthly,
                category: .music,
                nextBillingDate: calendar.date(byAdding: .day, value: 5, to: now) ?? now,
                iconName: "logo_spotify"
            ),
            Subscription(
                name: "iCloud+",
                price: 2.99,
                currencyCode: "USD",
                billingCycle: .monthly,
                category: .cloud,
                nextBillingDate: calendar.date(byAdding: .day, value: 11, to: now) ?? now,
                iconName: "logo_icloud"
            ),
            Subscription(
                name: "ChatGPT Plus",
                price: 20,
                currencyCode: "USD",
                billingCycle: .monthly,
                category: .productivity,
                nextBillingDate: calendar.date(byAdding: .day, value: 1, to: now) ?? now,
                iconName: "logo_chatgpt"
            ),
            Subscription(
                name: "YouTube Premium",
                price: 13.99,
                currencyCode: "USD",
                billingCycle: .monthly,
                category: .entertainment,
                nextBillingDate: calendar.date(byAdding: .day, value: 20, to: now) ?? now,
                iconName: "logo_youtube"
            ),
            Subscription(
                name: "Apple Fitness+",
                price: 9.99,
                currencyCode: "USD",
                billingCycle: .monthly,
                category: .fitness,
                nextBillingDate: calendar.date(byAdding: .day, value: 8, to: now) ?? now,
                isActive: false,
                iconName: "logo_fitness"
            ),
        ]

        for sample in samples {
            container.mainContext.insert(sample)
        }

        return container
    }()
}
