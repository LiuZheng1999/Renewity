import SwiftData
import SwiftUI

@main
struct RenewityApp: App {
    let container: ModelContainer
    @State private var proStore = ProStore()
    @State private var appLock = AppLockController()
    @State private var exchangeRates = ExchangeRateStore()
    @AppStorage("appearanceMode") private var appearanceMode = AppearancePreference.system.rawValue

    init() {
        AppConfig.seedCurrencyDefaultsIfNeeded()
        let schema = Schema([Subscription.self, AppCategory.self, AppPaymentMethod.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("无法创建数据容器：\(error)")
        }
        AppCategory.seedBuiltIns(in: container.mainContext)
        AppPaymentMethod.seedBuiltIns(in: container.mainContext)
        BillingCurrencyMigration.migrateIfNeeded(in: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .background {
                    WidgetSyncHost()
                }
                .environment(proStore)
                .environment(appLock)
                .environment(exchangeRates)
                .preferredColorScheme(AppearancePreference(rawValue: appearanceMode)?.colorScheme)
                .task {
                    await proStore.start()
                    await exchangeRates.refreshIfNeeded()
                }
        }
        .modelContainer(container)
    }
}
