import SwiftData
import SwiftUI

struct CloudSyncHost: View {
    @Query private var preferences: [AppPreferences]
    @Query private var categories: [AppCategory]
    @Query private var paymentMethods: [AppPaymentMethod]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("appearanceMode") private var appearanceMode = AppearancePreference.system.rawValue
    @AppStorage("remindersEnabled") private var remindersEnabled = true
    @AppStorage("reminderHour") private var reminderHour = 9
    @AppStorage("currencyCode") private var currencyCode = "CNY"
    @AppStorage("heroConvertToOtherCurrency") private var convertToOtherCurrency = true
    @AppStorage("heroConversionCurrencyCode") private var conversionCurrencyCode = ""
    @AppStorage("heroConversionCurrencyChosen") private var conversionCurrencyChosen = false
    @AppStorage(ProfileAvatarStore.revisionKey) private var avatarRevision = 0

    @State private var isApplyingRemote = false
    @State private var didBootstrap = false

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
            .task {
                await bootstrap()
            }
            .onChange(of: remoteStamp) { _, _ in
                applyRemote()
            }
            .onChange(of: localStamp) { _, _ in
                pushLocal()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    CloudKitMaintenance.dedupe(in: modelContext)
                    applyRemote()
                }
            }
    }

    private var remoteStamp: String {
        guard let prefs = preferences.first else { return "" }
        return "\(prefs.updatedAt.timeIntervalSince1970)|\(prefs.avatarJPEG?.count ?? 0)|\(prefs.appearanceMode)|\(prefs.reminderHour)|\(prefs.currencyCode)"
    }

    private var localStamp: String {
        "\(appearanceMode)|\(remindersEnabled)|\(reminderHour)|\(currencyCode)|\(convertToOtherCurrency)|\(conversionCurrencyCode)|\(conversionCurrencyChosen)|\(avatarRevision)"
    }

    private func bootstrap() async {
        guard !didBootstrap else { return }
        try? await Task.sleep(for: .seconds(1.2))
        AppCategory.seedBuiltIns(in: modelContext)
        AppPaymentMethod.seedBuiltIns(in: modelContext)
        CloudKitMaintenance.dedupe(in: modelContext)
        _ = AppPreferences.resolved(in: modelContext)
        try? modelContext.save()
        didBootstrap = true
        applyRemote()
    }

    private func applyRemote() {
        guard let prefs = preferences.max(by: { $0.updatedAt < $1.updatedAt }) else { return }
        isApplyingRemote = true
        appearanceMode = prefs.appearanceMode
        remindersEnabled = prefs.remindersEnabled
        reminderHour = min(max(prefs.reminderHour, 0), 23)
        currencyCode = prefs.currencyCode
        convertToOtherCurrency = prefs.heroConvertToOtherCurrency
        if prefs.heroConversionCurrencyChosen,
           AppConfig.selectedCurrencyCode(from: prefs.heroConversionCurrencyCode) != nil {
            conversionCurrencyChosen = true
            conversionCurrencyCode = prefs.heroConversionCurrencyCode
        } else if !conversionCurrencyChosen {
            conversionCurrencyCode = ""
        }
        if let data = prefs.avatarJPEG, data != ProfileAvatarStore.loadData() {
            ProfileAvatarStore.saveRawJPEG(data)
        } else if prefs.avatarJPEG == nil, ProfileAvatarStore.hasAvatar {
            // Keep local photo until a remote empty value is an intentional delete.
        }
        isApplyingRemote = false
    }

    private func pushLocal() {
        guard !isApplyingRemote, didBootstrap else { return }
        let prefs = AppPreferences.resolved(in: modelContext)
        prefs.appearanceMode = appearanceMode
        prefs.remindersEnabled = remindersEnabled
        prefs.reminderHour = reminderHour
        prefs.currencyCode = currencyCode
        prefs.heroConvertToOtherCurrency = convertToOtherCurrency
        prefs.heroConversionCurrencyCode = conversionCurrencyCode
        prefs.heroConversionCurrencyChosen = conversionCurrencyChosen
        prefs.avatarJPEG = ProfileAvatarStore.loadData()
        prefs.updatedAt = .now
        try? modelContext.save()
    }
}

enum CloudKitMaintenance {
    @MainActor
    static func dedupe(in context: ModelContext) {
        let categories = (try? context.fetch(FetchDescriptor<AppCategory>())) ?? []
        for extras in Dictionary(grouping: categories, by: \.identifier).values where extras.count > 1 {
            for extra in extras.dropFirst() {
                context.delete(extra)
            }
        }

        let methods = (try? context.fetch(FetchDescriptor<AppPaymentMethod>())) ?? []
        for extras in Dictionary(grouping: methods, by: \.identifier).values where extras.count > 1 {
            for extra in extras.dropFirst() {
                context.delete(extra)
            }
        }

        let prefs = (try? context.fetch(FetchDescriptor<AppPreferences>())) ?? []
        if prefs.count > 1 {
            let sorted = prefs.sorted { $0.updatedAt > $1.updatedAt }
            for extra in sorted.dropFirst() {
                context.delete(extra)
            }
        }
        try? context.save()
    }
}
