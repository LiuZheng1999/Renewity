import Foundation
import SwiftData

@Model
final class AppPreferences {
    var recordID: String = "app.preferences"
    var appearanceMode: String = "system"
    var remindersEnabled: Bool = true
    var reminderHour: Int = 9
    var currencyCode: String = "CNY"
    var heroConvertToOtherCurrency: Bool = true
    var heroConversionCurrencyCode: String = ""
    var heroConversionCurrencyChosen: Bool = false
    var avatarJPEG: Data?
    var updatedAt: Date = Date()

    init() {}

    @MainActor
    static func resolved(in context: ModelContext) -> AppPreferences {
        let descriptor = FetchDescriptor<AppPreferences>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let existing = (try? context.fetch(descriptor)) ?? []
        if let first = existing.first {
            for extra in existing.dropFirst() {
                context.delete(extra)
            }
            return first
        }
        let created = AppPreferences()
        created.appearanceMode = UserDefaults.standard.string(forKey: "appearanceMode") ?? "system"
        created.remindersEnabled = UserDefaults.standard.object(forKey: "remindersEnabled") as? Bool ?? true
        created.reminderHour = UserDefaults.standard.object(forKey: "reminderHour") as? Int ?? 9
        created.currencyCode = UserDefaults.standard.string(forKey: "currencyCode") ?? "CNY"
        created.heroConvertToOtherCurrency = UserDefaults.standard.object(forKey: "heroConvertToOtherCurrency") as? Bool ?? true
        created.heroConversionCurrencyCode = UserDefaults.standard.string(forKey: "heroConversionCurrencyCode") ?? ""
        created.heroConversionCurrencyChosen = UserDefaults.standard.object(forKey: AppConfig.conversionCurrencyChosenKey) as? Bool ?? false
        created.avatarJPEG = ProfileAvatarStore.loadData()
        created.updatedAt = .now
        context.insert(created)
        return created
    }
}
