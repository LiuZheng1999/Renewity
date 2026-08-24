import SwiftData
import SwiftUI
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

struct AppearanceSettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode = AppearancePreference.system.rawValue

    var body: some View {
        Form {
            Section {
                Picker("外观", selection: $appearanceMode) {
                    ForEach(AppearancePreference.allCases) { mode in
                        Text(mode.title).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.inline)
            } footer: {
                Text("选择浅色、深色，或跟随系统外观。")
            }
        }
        .navigationTitle("外观")
        .toolbarTitleDisplayMode(.inlineLarge)
    }
}

struct CurrencySettingsView: View {
    @AppStorage("currencyCode") private var currencyCode = "CNY"
    @AppStorage("heroConversionCurrencyCode") private var conversionCurrencyCode = ""
    @AppStorage("heroConversionCurrencyChosen") private var conversionCurrencyChosen = false
    @Environment(ExchangeRateStore.self) private var exchangeRates
    @Environment(ProStore.self) private var proStore
    @State private var showingCurrencyPicker = false
    @State private var showingConversionPicker = false
    @State private var showingPaywall = false
    @State private var pendingCurrencyCode: String?
    @State private var pendingConversionCurrencyCode: String?
    @State private var alertMessage: String?

    var body: some View {
        Form {
            Section {
                Button {
                    showingCurrencyPicker = true
                } label: {
                    HStack {
                        Text("默认货币")
                        Spacer()
                        Text(Formatters.currencyPickerTitle(for: currencyCode))
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .foregroundStyle(.primary)

                Button {
                    showingConversionPicker = true
                } label: {
                    HStack {
                        Text("第二种货币")
                        Spacer()
                        if let selectedConversionCurrencyCode {
                            Text(Formatters.currencyPickerTitle(for: selectedConversionCurrencyCode))
                                .foregroundStyle(.secondary)
                        } else {
                            Text("选择货币")
                                .foregroundStyle(.tertiary)
                        }
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .foregroundStyle(.primary)
            } footer: {
                Text("总览和分类合计按默认货币换算。轻点概览卡片可切换到第二种货币。选择货币需要 Renewity Pro。")
            }

            Section {
                LabeledContent("上次更新") {
                    Text(lastUpdatedText)
                        .foregroundStyle(.secondary)
                }

                Button {
                    Task { await refreshRatesManually() }
                } label: {
                    if exchangeRates.isLoading {
                        HStack {
                            Text("更新汇率")
                            Spacer()
                            ProgressView()
                        }
                    } else {
                        Text("更新汇率")
                    }
                }
                .foregroundStyle(.orange)
                .tint(.orange)
                .disabled(exchangeRates.isLoading)
            } header: {
                Text("汇率")
            } footer: {
                Text("每 5 天自动更新一次汇率，你也可以每天手动更新。")
            }
        }
        .navigationTitle("币种")
        .toolbarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCurrencyPicker, onDismiss: presentPaywallIfCurrencyLocked) {
            CurrencyPickerView(currencyCode: $currencyCode, onSelect: handleDefaultCurrencySelect)
        }
        .sheet(isPresented: $showingConversionPicker, onDismiss: presentPaywallIfCurrencyLocked) {
            CurrencyPickerView(
                currencyCode: Binding(
                    get: { selectedConversionCurrencyCode ?? "" },
                    set: { conversionCurrencyCode = $0 }
                ),
                onSelect: handleConversionCurrencySelect,
                excludedCodes: [currencyCode.uppercased()]
            )
        }
        .fullScreenCover(isPresented: $showingPaywall, onDismiss: applyPendingCurrencyIfPro) {
            PaywallView()
        }
        .alert(alertTitle, isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            if let alertMessage {
                Text(alertMessage)
            }
        }
    }

    private var selectedConversionCurrencyCode: String? {
        guard conversionCurrencyChosen else { return nil }
        return AppConfig.selectedCurrencyCode(from: conversionCurrencyCode)
    }

    private func handleDefaultCurrencySelect(_ code: String) {
        guard code != currencyCode else { return }
        if proStore.isPro {
            currencyCode = code
        } else {
            pendingCurrencyCode = code
        }
    }

    private func handleConversionCurrencySelect(_ code: String) {
        guard code.uppercased() != currencyCode.uppercased() else { return }
        if proStore.isPro {
            applyConversionCurrency(code)
        } else {
            pendingConversionCurrencyCode = code
        }
    }

    private func presentPaywallIfCurrencyLocked() {
        let hasPending = pendingCurrencyCode != nil || pendingConversionCurrencyCode != nil
        guard hasPending, !proStore.isPro else { return }
        DispatchQueue.main.async {
            showingPaywall = true
        }
    }

    private func applyPendingCurrencyIfPro() {
        if let pendingCurrencyCode, proStore.isPro {
            currencyCode = pendingCurrencyCode
        }
        if let pendingConversionCurrencyCode, proStore.isPro {
            applyConversionCurrency(pendingConversionCurrencyCode)
        }
        self.pendingCurrencyCode = nil
        self.pendingConversionCurrencyCode = nil
    }

    private func applyConversionCurrency(_ code: String) {
        conversionCurrencyCode = code
        conversionCurrencyChosen = true
    }

    private var lastUpdatedText: String {
        if let date = exchangeRates.updatedAt {
            Formatters.relativeUpdatedAt(date)
        } else {
            String(localized: "尚未更新")
        }
    }

    private var alertTitle: String {
        alertMessage == String(localized: "今天已经更新过汇率")
            ? String(localized: "提示")
            : String(localized: "无法更新")
    }

    private func refreshRatesManually() async {
        guard exchangeRates.canRefreshManually else {
            alertMessage = String(localized: "今天已经更新过汇率")
            return
        }
        let succeeded = await exchangeRates.refreshManually()
        if !succeeded {
            alertMessage = exchangeRates.errorMessage ?? String(localized: "无法获取最新汇率")
        }
    }
}

struct NotificationSettingsView: View {
    @Query private var subscriptions: [Subscription]
    @AppStorage("remindersEnabled") private var remindersEnabled = true
    @AppStorage("reminderHour") private var reminderHour = 9
    @State private var authorizationDenied = false

    var body: some View {
        Form {
            Section {
                Toggle("续订提醒", isOn: $remindersEnabled)
            } footer: {
                Text("按每个订阅的续订和试用设置发送本地通知。")
            }

            if remindersEnabled {
                Section("提醒时间") {
                    Picker("发送时间", selection: $reminderHour) {
                        ForEach(6..<22, id: \.self) { hour in
                            Text(verbatim: "\(hour):00").tag(hour)
                        }
                    }
                }
            }

            if authorizationDenied {
                Section {
                    Text("通知权限已关闭，请在系统设置中允许「\(AppConfig.appName)」发送通知。")
                        .foregroundStyle(.secondary)
                    #if os(iOS)
                    Button("打开系统设置") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    #endif
                }
            }
        }
        .navigationTitle("通知")
        .toolbarTitleDisplayMode(.inlineLarge)
        .task {
            await refreshAuthorization()
            applyReminderSettings()
        }
        .onChange(of: remindersEnabled) { _, _ in
            applyReminderSettings()
        }
        .onChange(of: reminderHour) { _, _ in
            applyReminderSettings()
        }
    }

    private func refreshAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationDenied = settings.authorizationStatus == .denied
        if remindersEnabled {
            await ReminderService.requestAuthorizationIfNeeded()
        }
    }

    private func applyReminderSettings() {
        ReminderService.rescheduleAll(subscriptions)
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image("AppMark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    Text(AppConfig.appName)
                        .font(.title2.bold())
                    Text("版本 \(AppConfig.versionText)")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .listRowBackground(Color.clear)
            }

            Section("应用") {
                LabeledContent("名称", value: AppConfig.appName)
                LabeledContent("版本", value: AppConfig.versionText)
                LabeledContent("类别", value: String(localized: "财务"))
            }
        }
        .navigationTitle("关于")
        .toolbarTitleDisplayMode(.inlineLarge)
    }
}

#Preview("外观") {
    NavigationStack { AppearanceSettingsView() }
}
