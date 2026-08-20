import Foundation

@Observable
final class ExchangeRateStore {
    private(set) var usdRates: [String: Double]
    private(set) var updatedAt: Date?
    private(set) var isLoading = false
    var errorMessage: String?

    private let cacheKey = "exchangeRatesUSD"
    private let cacheDateKey = "exchangeRatesUSDDate"
    private let lastManualKey = "exchangeRatesLastManualAt"
    private let autoRefreshInterval: TimeInterval = 5 * 24 * 60 * 60

    private var lastManualRefreshAt: Date? = nil

    private static let fallbackRates: [String: Double] = [
        "USD": 1,
        "CNY": 7.25,
        "HKD": 7.80,
        "TWD": 32.0,
        "EUR": 0.92,
        "JPY": 150,
        "GBP": 0.78,
        "KRW": 1380,
        "SGD": 1.35,
        "AUD": 1.52,
        "CAD": 1.37,
    ]

    init() {
        usdRates = Self.fallbackRates
        loadCache()
    }

    func convert(_ amount: Decimal, from sourceCode: String, to targetCode: String) -> Decimal? {
        let from = sourceCode.uppercased()
        let to = targetCode.uppercased()
        if from == to { return amount }
        guard let fromRate = usdRates[from], let toRate = usdRates[to], fromRate > 0 else {
            return nil
        }
        return amount * Decimal(toRate) / Decimal(fromRate)
    }

    func convertedMonthlyCost(of subscription: Subscription, to displayCode: String) -> Decimal? {
        convert(subscription.monthlyCost, from: subscription.resolvedCurrencyCode, to: displayCode)
    }

    var canRefreshManually: Bool {
        guard let lastManualRefreshAt else { return true }
        return !Calendar.current.isDateInToday(lastManualRefreshAt)
    }

    func refreshIfNeeded() async {
        if let updatedAt, Date().timeIntervalSince(updatedAt) < autoRefreshInterval, usdRates.count > 1 {
            return
        }
        _ = await refresh()
    }

    @discardableResult
    func refreshManually() async -> Bool {
        guard canRefreshManually else { return false }
        let succeeded = await refresh()
        if succeeded {
            lastManualRefreshAt = .now
            UserDefaults.standard.set(lastManualRefreshAt, forKey: lastManualKey)
        }
        return succeeded
    }

    @discardableResult
    func refresh() async -> Bool {
        isLoading = true
        defer { isLoading = false }
        guard let url = URL(string: "https://open.er-api.com/v6/latest/USD") else { return false }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let payload = try JSONDecoder().decode(OpenERResponse.self, from: data)
            guard payload.result == "success", !payload.rates.isEmpty else {
                errorMessage = String(localized: "汇率暂时不可用")
                return false
            }
            var rates = payload.rates
            rates["USD"] = 1
            usdRates = rates
            updatedAt = .now
            errorMessage = nil
            saveCache()
            return true
        } catch {
            errorMessage = updatedAt == nil
                ? String(localized: "无法获取最新汇率，已使用估算值")
                : String(localized: "无法获取最新汇率")
            return false
        }
    }

    private func loadCache() {
        let defaults = UserDefaults.standard
        lastManualRefreshAt = defaults.object(forKey: lastManualKey) as? Date
        guard let data = defaults.data(forKey: cacheKey),
              let rates = try? JSONDecoder().decode([String: Double].self, from: data),
              !rates.isEmpty
        else { return }
        usdRates = rates
        updatedAt = defaults.object(forKey: cacheDateKey) as? Date
    }

    private func saveCache() {
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(usdRates) {
            defaults.set(data, forKey: cacheKey)
        }
        defaults.set(updatedAt, forKey: cacheDateKey)
    }
}

private struct OpenERResponse: Decodable {
    var result: String
    var rates: [String: Double]
}
