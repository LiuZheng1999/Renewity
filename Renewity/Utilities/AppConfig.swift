import Foundation
import SwiftUI

enum AppConfig {
    static let appName = "Renewity"
    static let supportEmail = "philiptrip1975@gmail.com"
    static let appStoreID = ""
    static let freeSubscriptionLimit = 6
    /// GitHub Pages 站点（仓库 Settings → Pages → Deploy from branch，文件夹选 `docs`）。
    static let legalWebsiteURL = URL(string: "https://liuzheng1999.github.io/Renewity")!

    static var privacyPolicyWebURL: URL {
        legalWebsiteURL.appendingPathComponent("privacy/")
    }

    static var termsOfUseWebURL: URL {
        legalWebsiteURL.appendingPathComponent("terms/")
    }

    static var supportWebsiteURL: URL {
        legalWebsiteURL.appendingPathComponent("support/")
    }

    static let instagramUsername = "yanming367"
    static let xUsername = "AidePearce89391"

    static var instagramURL: URL {
        URL(string: "https://www.instagram.com/\(instagramUsername)")!
    }

    static var xURL: URL {
        URL(string: "https://x.com/\(xUsername)")!
    }

    static let monthlyProductID = "Renewity_Monthly"
    static let yearlyProductID = "Renewity_Yearly"
    static let lifetimeProductID = "Renewity_Premium"

    static var productIDs: Set<String> {
        [monthlyProductID, yearlyProductID, lifetimeProductID]
    }

    static var appStoreWriteReviewURL: URL? {
        guard !appStoreID.isEmpty else { return nil }
        return URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")
    }

    static var shareMessage: String {
        var message = String(localized: "我在用「\(appName)」管理订阅开支，推荐你也试试。")
        if let url = appStoreWriteReviewURL {
            message += " \(url.absoluteString)"
        }
        return message
    }

    static var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return String(localized: "app.versionWithBuild", defaultValue: "\(version)（\(build)）")
    }

    static var supportedCurrencies: [(code: String, name: String)] {
        [
            ("CNY", String(localized: "人民币")),
            ("USD", String(localized: "美元")),
            ("HKD", String(localized: "港币")),
            ("TWD", String(localized: "新台币")),
            ("EUR", String(localized: "欧元")),
            ("JPY", String(localized: "日元")),
            ("GBP", String(localized: "英镑")),
            ("KRW", String(localized: "韩元")),
            ("SGD", String(localized: "新加坡元")),
            ("AUD", String(localized: "澳元")),
            ("CAD", String(localized: "加元")),
        ]
    }

    static func currencyName(for code: String) -> String {
        supportedCurrencies.first { $0.code == code }?.name ?? code
    }

    static func isSelectableCurrency(_ code: String) -> Bool {
        if historicCurrencyCodes.contains(code) { return false }
        let name = Locale.current.localizedString(forCurrencyCode: code) ?? ""
        return !hasHistoricYearRange(name)
    }

    private static func hasHistoricYearRange(_ name: String) -> Bool {
        name.range(
            of: #"\((?:19|20)\d{2}\s*[–−-]\s*(?:19|20)\d{2}\)"#,
            options: .regularExpression
        ) != nil
    }

    /// ISO 4217 codes that have been withdrawn and replaced.
    private static let historicCurrencyCodes: Set<String> = [
        "ADP", "AFA", "ALK", "ANG", "AOK", "AON", "AOR", "ARA", "ARL", "ARM", "ARP", "ARY", "ATS", "AYM", "AZM",
        "BAD", "BAN", "BEC", "BEF", "BEL", "BGL", "BGM", "BGN", "BGO", "BOL", "BOP", "BRB", "BRC", "BRE", "BRN", "BRR", "BRZ",
        "BUK", "BYB", "BYR",
        "CLE", "CNX", "CSD", "CSE", "CSK", "CUC", "CYP",
        "DDM", "DEM",
        "ECS", "ECV", "EEK", "ESA", "ESB", "ESP",
        "FIM", "FRF",
        "GEK", "GHC", "GHP", "GNE", "GNS", "GQE", "GRD", "GWE", "GWP",
        "HRD", "HRK",
        "IEP", "ILP", "ILR", "ISJ", "ITL",
        "KRH", "KRO",
        "LAJ", "LSM", "LTL", "LTT", "LUC", "LUF", "LUL", "LVL", "LVR",
        "MAF", "MCF", "MDC", "MGF", "MKN", "MLF", "MRO", "MTL", "MTP", "MVP", "MVQ", "MXP", "MZE", "MZM",
        "NIC", "NLG",
        "PEH", "PEI", "PES", "PLZ", "PTE",
        "RHD", "ROL", "RUR",
        "SDD", "SDP", "SIT", "SKK", "SML", "SRG", "STD", "SUR", "SVC",
        "TJR", "TLE", "TMM", "TPE", "TRL",
        "UAK", "UGS", "USS", "UYN", "UYP",
        "VEB", "VEF", "VNC", "VNN",
        "XBA", "XBB", "XBC", "XBD", "XEU", "XFO", "XFU", "XRE", "XTS", "XXX",
        "YDD", "YUD", "YUG", "YUM", "YUN", "YUR",
        "ZAL", "ZMK", "ZRN", "ZRZ", "ZWC", "ZWD", "ZWN", "ZWR", "ZWL",
    ]

    static let lastCreatedPaymentMethodKey = "lastCreatedPaymentMethodID"
    static let lastCreatedBillingDateKindKey = "lastCreatedBillingDateKind"
    static let currencyStorageKey = "currencyCode"
    static let conversionCurrencyStorageKey = "heroConversionCurrencyCode"
    static let conversionCurrencyChosenKey = "heroConversionCurrencyChosen"

    static var localeCurrencyCode: String {
        if let regionCode = Locale.current.region?.identifier {
            let locale = Locale(identifier: "und_\(regionCode)")
            if let code = normalizedSelectableCurrency(locale.currency?.identifier) {
                return code
            }
        }
        if let code = normalizedSelectableCurrency(Locale.current.currency?.identifier) {
            return code
        }
        return "USD"
    }

    private static func normalizedSelectableCurrency(_ raw: String?) -> String? {
        let code = raw?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() ?? ""
        guard !code.isEmpty, isSelectableCurrency(code) else { return nil }
        return code
    }

    static func selectedCurrencyCode(from raw: String?) -> String? {
        normalizedSelectableCurrency(raw)
    }

    static func seedCurrencyDefaultsIfNeeded() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: currencyStorageKey) == nil {
            defaults.set(localeCurrencyCode, forKey: currencyStorageKey)
        }
        // Second display currency must be chosen by the user (Pro).
        // Clear the previous automatic CNY/USD seed once.
        if defaults.object(forKey: conversionCurrencyChosenKey) == nil {
            defaults.set("", forKey: conversionCurrencyStorageKey)
            defaults.set(false, forKey: conversionCurrencyChosenKey)
        }
    }
}

enum AppearancePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: String(localized: "跟随系统")
        case .light: String(localized: "浅色")
        case .dark: String(localized: "深色")
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
