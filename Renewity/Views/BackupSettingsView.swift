import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct BackupSettingsView: View {
    @Environment(ProStore.self) private var proStore
    @Environment(\.modelContext) private var modelContext
    @Query private var subscriptions: [Subscription]
    @Query(sort: \AppCategory.sortOrder) private var categories: [AppCategory]
    @Query(sort: \AppPaymentMethod.sortOrder) private var paymentMethods: [AppPaymentMethod]
    @AppStorage("currencyCode") private var currencyCode = "CNY"
    @AppStorage("iCloudBackupEnabled") private var iCloudBackupEnabled = true

    @State private var showingPaywall = false
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var confirmReplace = false
    @State private var confirmCloudRestore = false
    @State private var pendingImportData: Data?
    @State private var message: String?
    @State private var exportDocument = BackupDocument(payload: .empty)
    @State private var lastBackupDate = CloudBackupService.lastBackupDate
    @State private var isCloudBusy = false

    var body: some View {
        List {
            Section {
                Toggle("自动备份到 iCloud", isOn: Binding(
                    get: { iCloudBackupEnabled && proStore.isPro },
                    set: { newValue in
                        if proStore.isPro {
                            iCloudBackupEnabled = newValue
                            if newValue {
                                Task { await backupToCloud() }
                            }
                        } else {
                            showingPaywall = true
                        }
                    }
                ))
                Button {
                    performPro {
                        Task { await backupToCloud() }
                    }
                } label: {
                    Label("立即备份到 iCloud", systemImage: "icloud.and.arrow.up")
                }
                .disabled(isCloudBusy)
                Button {
                    performPro { confirmCloudRestore = true }
                } label: {
                    Label("从 iCloud 恢复", systemImage: "icloud.and.arrow.down")
                }
                .disabled(isCloudBusy)
            } header: {
                Text("云备份")
            } footer: {
                if !proStore.isPro {
                    Text("云备份是 Pro 功能。")
                } else if !CloudBackupService.isAvailable {
                    Text("请在系统设置中登录 Apple 账户，并打开 iCloud Drive。")
                } else if let lastBackupDate {
                    Text("上次云备份：\(Formatters.mediumDateTime(lastBackupDate))。备份保存在你的 iCloud Drive 中，换机登录同一账户即可恢复。")
                } else {
                    Text("备份保存在你的 iCloud Drive 中，换机登录同一 Apple 账户即可恢复。")
                }
            }

            Section {
                Button {
                    performPro { prepareExport() }
                } label: {
                    Label("导出到文件", systemImage: "square.and.arrow.up")
                }

                Button {
                    performPro { showingImporter = true }
                } label: {
                    Label("从文件恢复", systemImage: "square.and.arrow.down")
                }
            } header: {
                Text("文件")
            } footer: {
                Text("也可以导出为 JSON，保存到文件 App 或其他位置。")
            }

            if let message {
                Section {
                    Text(message)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("数据备份")
        .toolbarTitleDisplayMode(.inlineLarge)
        .fileExporter(
            isPresented: $showingExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: String(localized: "Renewity备份")
        ) { result in
            switch result {
            case .success:
                message = String(localized: "备份已导出。")
            case .failure(let error):
                message = error.localizedDescription
            }
        }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                loadImport(from: url)
            case .failure(let error):
                message = error.localizedDescription
            }
        }
        .confirmationDialog("恢复备份", isPresented: $confirmReplace, titleVisibility: .visible) {
            Button("替换当前数据", role: .destructive) {
                if let pendingImportData {
                    importBackup(pendingImportData)
                }
            }
            Button("取消", role: .cancel) {
                pendingImportData = nil
            }
        } message: {
            Text("恢复后将覆盖现有订阅、自定义分类和自定义支付方式，此操作无法撤销。")
        }
        .confirmationDialog("从 iCloud 恢复", isPresented: $confirmCloudRestore, titleVisibility: .visible) {
            Button("替换当前数据", role: .destructive) {
                Task { await restoreFromCloud() }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("将用 iCloud 备份覆盖现有订阅、自定义分类和自定义支付方式，此操作无法撤销。")
        }
        .fullScreenCover(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    private func performPro(_ action: () -> Void) {
        if proStore.isPro {
            action()
        } else {
            showingPaywall = true
        }
    }

    private func currentPayload() -> BackupPayload {
        CloudBackupService.makePayload(
            currencyCode: currencyCode,
            subscriptions: subscriptions,
            categories: categories,
            paymentMethods: paymentMethods
        )
    }

    private func prepareExport() {
        exportDocument = BackupDocument(payload: currentPayload())
        showingExporter = true
    }

    private func backupToCloud() async {
        isCloudBusy = true
        defer { isCloudBusy = false }
        do {
            let payload = currentPayload()
            try await Task.detached {
                try CloudBackupService.save(payload)
            }.value
            lastBackupDate = CloudBackupService.lastBackupDate
            message = String(localized: "已备份到 iCloud。")
        } catch {
            message = error.localizedDescription
        }
    }

    private func restoreFromCloud() async {
        isCloudBusy = true
        defer { isCloudBusy = false }
        do {
            let payload = try await Task.detached {
                try CloudBackupService.load()
            }.value
            apply(payload)
            message = String(localized: "已从 iCloud 恢复 \(payload.subscriptions.count) 个订阅。")
        } catch {
            message = error.localizedDescription
        }
    }

    private func loadImport(from url: URL) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed { url.stopAccessingSecurityScopedResource() }
        }
        do {
            pendingImportData = try Data(contentsOf: url)
            confirmReplace = true
        } catch {
            message = error.localizedDescription
        }
    }

    private func importBackup(_ data: Data) {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            apply(try decoder.decode(BackupPayload.self, from: data))
            message = String(localized: "已恢复备份。")
        } catch {
            message = String(localized: "无法读取备份文件。")
        }
    }

    private func apply(_ payload: BackupPayload) {
        for subscription in subscriptions {
            ReminderService.cancel(id: subscription.id)
            modelContext.delete(subscription)
        }
        for category in categories where !category.isBuiltIn {
            modelContext.delete(category)
        }
        for method in paymentMethods where !method.isBuiltIn {
            modelContext.delete(method)
        }
        try? modelContext.save()

        let currentCategories = (try? modelContext.fetch(FetchDescriptor<AppCategory>())) ?? []
        for item in payload.categories {
            if let existing = currentCategories.first(where: { $0.identifier == item.identifier }) {
                existing.name = item.name
                existing.iconName = item.iconName
                existing.colorHex = item.colorHex
                existing.sortOrder = item.sortOrder
                existing.isBuiltIn = false
            } else {
                modelContext.insert(
                    AppCategory(
                        identifier: item.identifier,
                        name: item.name,
                        iconName: item.iconName,
                        colorHex: item.colorHex,
                        isBuiltIn: false,
                        sortOrder: item.sortOrder
                    )
                )
            }
        }

        for item in payload.paymentMethods ?? [] {
            modelContext.insert(
                AppPaymentMethod(
                    identifier: item.identifier,
                    name: item.name,
                    iconName: item.iconName,
                    colorHex: item.colorHex,
                    isBuiltIn: false,
                    sortOrder: item.sortOrder
                )
            )
        }

        for item in payload.subscriptions {
            let paymentID = PaymentMethod.normalizedID(item.paymentMethodRaw ?? PaymentMethod.applePay.rawValue)
            let subscription = Subscription(
                name: item.name,
                price: Decimal(item.price),
                currencyCode: {
                    let raw = item.currencyCode?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    return Subscription.normalizedCurrencyCode(raw.isEmpty ? payload.currencyCode : raw)
                }(),
                billingCycle: BillingCycle(rawValue: item.billingCycleRaw) ?? .monthly,
                category: SubscriptionCategory(rawValue: item.categoryRaw) ?? .other,
                nextBillingDate: item.nextBillingDate,
                notes: item.notes,
                isActive: item.isActive,
                iconName: item.iconName,
                paymentMethod: PaymentMethod(rawValue: paymentID) ?? .other,
                customCycleValue: item.customCycleValue ?? 1,
                customCycleUnit: CustomCycleUnit(rawValue: item.customCycleUnitRaw ?? "") ?? .month,
                accentColorHex: item.accentColorHex ?? "",
                remindBeforeBilling: item.remindBeforeBilling,
                reminderOffsets: item.reminderOffsetsRaw.map {
                    Subscription.decodeReminderOffsets($0, enabled: item.remindBeforeBilling)
                },
                trialEndDate: item.trialEndDate,
                trialReminderOffsets: item.trialReminderOffsetsRaw.map {
                    Subscription.decodeStoredOffsets($0)
                },
                managementURL: item.managementURL ?? "",
                doesRenew: item.doesRenew ?? true
            )
            subscription.id = item.id
            subscription.categoryRaw = item.categoryRaw
            subscription.paymentMethodRaw = paymentID
            if let managementURL = item.managementURL {
                subscription.managementURL = managementURL
            } else if let suggested = SubscriptionManageLinks.suggested(iconName: item.iconName, name: item.name) {
                subscription.managementURL = suggested.absoluteString
            }
            modelContext.insert(subscription)
        }

        currencyCode = payload.currencyCode
        if let appearanceMode = payload.appearanceMode {
            UserDefaults.standard.set(appearanceMode, forKey: "appearanceMode")
        }
        if let remindersEnabled = payload.remindersEnabled {
            UserDefaults.standard.set(remindersEnabled, forKey: "remindersEnabled")
        }
        if let reminderHour = payload.reminderHour {
            UserDefaults.standard.set(min(max(reminderHour, 0), 23), forKey: "reminderHour")
        }
        if let convert = payload.heroConvertToOtherCurrency {
            UserDefaults.standard.set(convert, forKey: "heroConvertToOtherCurrency")
        }
        if let conversionCode = payload.heroConversionCurrencyCode {
            UserDefaults.standard.set(conversionCode, forKey: "heroConversionCurrencyCode")
        }
        if let chosen = payload.heroConversionCurrencyChosen {
            UserDefaults.standard.set(chosen, forKey: AppConfig.conversionCurrencyChosenKey)
        } else if let conversionCode = payload.heroConversionCurrencyCode {
            UserDefaults.standard.set(
                AppConfig.selectedCurrencyCode(from: conversionCode) != nil,
                forKey: AppConfig.conversionCurrencyChosenKey
            )
        }
        if let avatarJPEG = payload.avatarJPEG {
            ProfileAvatarStore.saveRawJPEG(avatarJPEG)
        }
        ReminderService.rescheduleAll(
            (try? modelContext.fetch(FetchDescriptor<Subscription>())) ?? []
        )
        pendingImportData = nil
        message = String(localized: "已恢复 \(payload.subscriptions.count) 个订阅。")
    }
}

nonisolated struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var payload: BackupPayload

    init(payload: BackupPayload) {
        self.payload = payload
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        payload = try decoder.decode(BackupPayload.self, from: data)
    }

    func fileWrapper(configuration _: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(payload)
        return FileWrapper(regularFileWithContents: data)
    }
}

nonisolated struct BackupPayload: Codable, Sendable {
    var version: Int
    var exportedAt: Date
    var currencyCode: String
    var subscriptions: [BackupSubscription]
    var categories: [BackupCategory]
    var paymentMethods: [BackupPaymentMethod]?
    var appearanceMode: String?
    var remindersEnabled: Bool?
    var reminderHour: Int?
    var heroConvertToOtherCurrency: Bool?
    var heroConversionCurrencyCode: String?
    var heroConversionCurrencyChosen: Bool?
    var avatarJPEG: Data?

    static let empty = BackupPayload(
        version: 2,
        exportedAt: .now,
        currencyCode: "CNY",
        subscriptions: [],
        categories: [],
        paymentMethods: []
    )
}

nonisolated struct BackupSubscription: Codable, Sendable {
    var id: UUID
    var name: String
    var price: Double
    var billingCycleRaw: String
    var categoryRaw: String
    var nextBillingDate: Date
    var notes: String
    var isActive: Bool
    var iconName: String
    var paymentMethodRaw: String?
    var customCycleValue: Int?
    var customCycleUnitRaw: String?
    var accentColorHex: String?
    var remindBeforeBilling: Bool
    var reminderOffsetsRaw: String?
    var trialEndDate: Date?
    var trialReminderOffsetsRaw: String?
    var currencyCode: String?
    var managementURL: String?
    var doesRenew: Bool?

    @MainActor
    init(_ subscription: Subscription) {
        id = subscription.id
        name = subscription.name
        price = NSDecimalNumber(decimal: subscription.price).doubleValue
        billingCycleRaw = subscription.billingCycleRaw
        categoryRaw = subscription.categoryRaw
        nextBillingDate = subscription.nextBillingDate
        notes = subscription.notes
        isActive = subscription.isActive
        iconName = subscription.iconName
        paymentMethodRaw = subscription.paymentMethodRaw
        customCycleValue = subscription.customCycleValue
        customCycleUnitRaw = subscription.customCycleUnitRaw
        accentColorHex = subscription.accentColorHex
        remindBeforeBilling = subscription.remindBeforeBilling
        reminderOffsetsRaw = subscription.reminderOffsets.map(String.init).joined(separator: ",")
        trialEndDate = subscription.trialEndDate
        trialReminderOffsetsRaw = subscription.trialEndDate == nil
            ? nil
            : subscription.trialReminderOffsets.map(String.init).joined(separator: ",")
        currencyCode = subscription.resolvedCurrencyCode
        managementURL = subscription.managementURL.isEmpty ? nil : subscription.managementURL
        doesRenew = subscription.doesRenew
    }
}

nonisolated struct BackupPaymentMethod: Codable, Sendable {
    var identifier: String
    var name: String
    var iconName: String
    var colorHex: String
    var sortOrder: Int

    @MainActor
    init(_ method: AppPaymentMethod) {
        identifier = method.identifier
        name = method.name
        iconName = method.iconName
        colorHex = method.colorHex
        sortOrder = method.sortOrder
    }
}

nonisolated struct BackupCategory: Codable, Sendable {
    var identifier: String
    var name: String
    var iconName: String
    var colorHex: String
    var sortOrder: Int

    @MainActor
    init(_ category: AppCategory) {
        identifier = category.identifier
        name = category.name
        iconName = category.iconName
        colorHex = category.colorHex
        sortOrder = category.sortOrder
    }
}

nonisolated enum CloudBackupError: LocalizedError, Sendable {
    case unavailable
    case notFound

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return String(localized: "iCloud 不可用，请在系统设置中登录 Apple 账户并打开 iCloud Drive。")
        case .notFound:
            return String(localized: "iCloud 里还没有备份。")
        }
    }
}

nonisolated enum CloudBackupService {
    static let containerID = "iCloud.Maoxia-Xiang.Renewity"
    static let fileName = "Renewity备份.json"
    static let lastBackupKey = "lastCloudBackupAt"

    static var isAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    static var lastBackupDate: Date? {
        let interval = UserDefaults.standard.double(forKey: lastBackupKey)
        guard interval > 0 else { return nil }
        return Date(timeIntervalSince1970: interval)
    }

    @MainActor
    static func makePayload(
        currencyCode: String,
        subscriptions: [Subscription],
        categories: [AppCategory],
        paymentMethods: [AppPaymentMethod]
    ) -> BackupPayload {
        BackupPayload(
            version: 2,
            exportedAt: .now,
            currencyCode: currencyCode,
            subscriptions: subscriptions.map { BackupSubscription($0) },
            categories: categories.filter { !$0.isBuiltIn }.map { BackupCategory($0) },
            paymentMethods: paymentMethods.filter { !$0.isBuiltIn }.map { BackupPaymentMethod($0) },
            appearanceMode: UserDefaults.standard.string(forKey: "appearanceMode"),
            remindersEnabled: UserDefaults.standard.object(forKey: "remindersEnabled") as? Bool,
            reminderHour: UserDefaults.standard.object(forKey: "reminderHour") as? Int,
            heroConvertToOtherCurrency: UserDefaults.standard.object(forKey: "heroConvertToOtherCurrency") as? Bool,
            heroConversionCurrencyCode: UserDefaults.standard.string(forKey: "heroConversionCurrencyCode"),
            heroConversionCurrencyChosen: UserDefaults.standard.object(forKey: AppConfig.conversionCurrencyChosenKey) as? Bool,
            avatarJPEG: ProfileAvatarStore.loadData()
        )
    }

    static func save(_ payload: BackupPayload) throws {
        guard let url = backupFileURL() else { throw CloudBackupError.unavailable }
        let data = try encode(payload)
        var coordinatorError: NSError?
        var writeError: Error?
        NSFileCoordinator().coordinate(writingItemAt: url, options: .forReplacing, error: &coordinatorError) { fileURL in
            do {
                try data.write(to: fileURL, options: .atomic)
            } catch {
                writeError = error
            }
        }
        if let coordinatorError { throw coordinatorError }
        if let writeError { throw writeError }
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastBackupKey)
    }

    static func load() throws -> BackupPayload {
        guard let url = backupFileURL() else { throw CloudBackupError.unavailable }
        downloadIfNeeded(url)
        var coordinatorError: NSError?
        var fileData: Data?
        var readFailed = false
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinatorError) { fileURL in
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                readFailed = true
                return
            }
            do {
                fileData = try Data(contentsOf: fileURL)
            } catch {
                readFailed = true
            }
        }
        if let coordinatorError { throw coordinatorError }
        guard !readFailed, let fileData else { throw CloudBackupError.notFound }
        return try decode(fileData)
    }

    private static func backupFileURL() -> URL? {
        guard let container = FileManager.default.url(forUbiquityContainerIdentifier: containerID) else {
            return nil
        }
        let documents = container.appendingPathComponent("Documents", isDirectory: true)
        try? FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
        return documents.appendingPathComponent(fileName)
    }

    private static func downloadIfNeeded(_ url: URL) {
        guard let values = try? url.resourceValues(forKeys: [.isUbiquitousItemKey, .ubiquitousItemDownloadingStatusKey]),
              values.isUbiquitousItem == true
        else { return }
        if values.ubiquitousItemDownloadingStatus != URLUbiquitousItemDownloadingStatus.current {
            try? FileManager.default.startDownloadingUbiquitousItem(at: url)
        }
    }

    private static func encode(_ payload: BackupPayload) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }

    private static func decode(_ data: Data) throws -> BackupPayload {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(BackupPayload.self, from: data)
    }
}
