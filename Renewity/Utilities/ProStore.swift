import Foundation
import StoreKit

@Observable
final class ProStore {
    private(set) var hasStoreEntitlement = false
    private(set) var products: [Product] = []
    private(set) var isLoading = false
    var errorMessage: String?
    private let previewUnlocked: Bool

    #if DEBUG
    var debugUnlocked: Bool {
        didSet {
            UserDefaults.standard.set(debugUnlocked, forKey: "debugUnlockPro")
        }
    }
    #endif

    var isPro: Bool {
        #if DEBUG
        hasStoreEntitlement || debugUnlocked || previewUnlocked
        #else
        hasStoreEntitlement || previewUnlocked
        #endif
    }

    var monthlyProduct: Product? {
        products.first { $0.id == AppConfig.monthlyProductID }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == AppConfig.yearlyProductID }
    }

    var lifetimeProduct: Product? {
        products.first { $0.id == AppConfig.lifetimeProductID }
    }

    init(previewUnlocked: Bool = false) {
        self.previewUnlocked = previewUnlocked
        #if DEBUG
        debugUnlocked = UserDefaults.standard.bool(forKey: "debugUnlockPro")
        #else
        UserDefaults.standard.removeObject(forKey: "debugUnlockPro")
        #endif
    }

    func canAddSubscription(currentCount: Int) -> Bool {
        isPro || currentCount < AppConfig.freeSubscriptionLimit
    }

    func start() async {
        await refreshEntitlements()
        await loadProducts()
        Task {
            await listenForTransactions()
        }
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: AppConfig.productIDs)
                .sorted { $0.price < $1.price }
            if products.isEmpty {
                errorMessage = String(localized: "App Store 未返回套餐。请确认产品已创建，本地调试请在 Scheme 中选用 Products.storekit。")
            }
        } catch {
            products = []
            errorMessage = error.localizedDescription
        }
    }

    func purchase(_ product: Product) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restore() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if !isPro {
                errorMessage = String(localized: "没有找到可恢复的购买。")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refreshEntitlements() async {
        var entitled = false
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if AppConfig.productIDs.contains(transaction.productID) {
                entitled = true
            }
        }
        hasStoreEntitlement = entitled
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            guard let transaction = try? checkVerified(result) else { continue }
            await transaction.finish()
            await refreshEntitlements()
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}
