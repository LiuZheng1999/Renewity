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
    @Environment(ExchangeRateStore.self) private var exchangeRates
    @Environment(ProStore.self) private var proStore
    @State private var showingCurrencyPicker = false
    @State private var showingPaywall = false
    @State private var pendingCurrencyCode: String?
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
            } footer: {
                Text("总览、分类合计和小组件会按参考汇率换算到此货币，仅供参考，不会改写各笔订阅记下的金额。")
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
        .sheet(isPresented: $showingPaywall, onDismiss: applyPendingCurrencyIfPro) {
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

    private func handleDefaultCurrencySelect(_ code: String) {
        guard code != currencyCode else { return }
        if proStore.isPro {
            currencyCode = code
        } else {
            pendingCurrencyCode = code
        }
    }

    private func presentPaywallIfCurrencyLocked() {
        guard pendingCurrencyCode != nil, !proStore.isPro else { return }
        DispatchQueue.main.async {
            showingPaywall = true
        }
    }

    private func applyPendingCurrencyIfPro() {
        guard let pendingCurrencyCode else { return }
        if proStore.isPro {
            currencyCode = pendingCurrencyCode
        }
        self.pendingCurrencyCode = nil
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
                Toggle("续费提醒", isOn: $remindersEnabled)
            } footer: {
                Text("按每个订阅的续费和试用设置发送本地通知。")
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
    @Environment(\.openURL) private var openURL

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                        .frame(width: 72, height: 72)
                        .background(Color.accentColor.gradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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

            Section("法律") {
                Button {
                    openURL(AppConfig.privacyPolicyWebURL)
                } label: {
                    Label("隐私政策（网页）", systemImage: "safari")
                }
                Button {
                    openURL(AppConfig.termsOfUseWebURL)
                } label: {
                    Label("用户协议（网页）", systemImage: "safari")
                }
            }
        }
        .navigationTitle("关于")
        .toolbarTitleDisplayMode(.inlineLarge)
    }
}

#Preview("外观") {
    NavigationStack { AppearanceSettingsView() }
}
