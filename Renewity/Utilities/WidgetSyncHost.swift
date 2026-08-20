import SwiftData
import SwiftUI

struct WidgetSyncHost: View {
    @Query private var subscriptions: [Subscription]
    @Query(sort: \AppCategory.sortOrder) private var categories: [AppCategory]
    @Query(sort: \AppPaymentMethod.sortOrder) private var paymentMethods: [AppPaymentMethod]
    @AppStorage("currencyCode") private var currencyCode = "CNY"
    @AppStorage("iCloudBackupEnabled") private var iCloudBackupEnabled = true
    @Environment(\.scenePhase) private var scenePhase
    @Environment(ProStore.self) private var proStore
    @Environment(ExchangeRateStore.self) private var exchangeRates
    @State private var cloudBackupTask: Task<Void, Never>?

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
            .onAppear(perform: sync)
            .onChange(of: syncToken) { _, _ in
                sync()
                scheduleCloudBackup()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    sync()
                    ReminderService.rescheduleAll(subscriptions)
                } else if phase == .background {
                    backupToCloudNow()
                }
            }
    }

    private var syncToken: String {
        let items = subscriptions
            .map { "\($0.id.uuidString)|\($0.name)|\($0.price)|\($0.resolvedCurrencyCode)|\($0.isActive)|\($0.nextBillingDate.timeIntervalSince1970)|\($0.categoryRaw)|\($0.trialEndDate?.timeIntervalSince1970 ?? 0)" }
            .sorted()
            .joined(separator: ";")
        let categoryToken = categories.map { "\($0.identifier)\($0.colorHex)" }.joined()
        let paymentToken = paymentMethods.map { "\($0.identifier)\($0.sortOrder)" }.joined()
        let ratesToken = String(exchangeRates.updatedAt?.timeIntervalSince1970 ?? 0)
        return items + "|" + currencyCode + "|" + categoryToken + "|" + paymentToken + "|" + ratesToken
    }

    private func sync() {
        WidgetSync.refresh(
            subscriptions: subscriptions,
            categories: categories,
            currencyCode: currencyCode,
            exchangeRates: exchangeRates
        )
    }

    private func scheduleCloudBackup() {
        guard proStore.isPro, iCloudBackupEnabled, CloudBackupService.isAvailable else { return }
        cloudBackupTask?.cancel()
        cloudBackupTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            backupToCloudNow()
        }
    }

    private func backupToCloudNow() {
        guard proStore.isPro, iCloudBackupEnabled, CloudBackupService.isAvailable else { return }
        let payload = CloudBackupService.makePayload(
            currencyCode: currencyCode,
            subscriptions: subscriptions,
            categories: categories,
            paymentMethods: paymentMethods
        )
        try? CloudBackupService.save(payload)
    }
}
