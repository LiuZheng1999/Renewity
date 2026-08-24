import LocalAuthentication
import SwiftUI

struct PrivacySecurityView: View {
    @AppStorage("appLockEnabled") private var appLockEnabled = false
    @Environment(AppLockController.self) private var appLock
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                Toggle("锁定 App", isOn: $appLockEnabled)
            } footer: {
                Text("离开 App 后再回来时，需要面容 ID、触控 ID 或设备密码才能查看订阅数据。")
            }

            Section("数据") {
                LabeledContent("存储位置", value: String(localized: "本机，并可通过 iCloud 在设备间同步"))
                LabeledContent("账户", value: String(localized: "不需要登录"))
                LabeledContent("分析", value: String(localized: "不收集"))
            }

            Section("隐私说明") {
                Text("订阅名称、金额和日期都保存在你的设备上。续订提醒使用系统本地通知，不会上传到服务器。购买通过 Apple 完成。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("隐私与安全")
        .toolbarTitleDisplayMode(.inlineLarge)
        .onChange(of: appLockEnabled) { _, enabled in
            if enabled {
                Task {
                    let success = await appLock.authenticate(reason: String(localized: "开启 App 锁定"))
                    if success {
                        appLock.lockIfNeeded()
                    } else {
                        appLockEnabled = false
                        errorMessage = String(localized: "未能完成验证，App 锁定未开启。")
                    }
                }
            } else {
                appLock.isLocked = false
            }
        }
    }
}

@Observable
final class AppLockController {
    var isLocked = false

    var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: "appLockEnabled")
    }

    func lockIfNeeded() {
        if isEnabled {
            isLocked = true
        }
    }

    @discardableResult
    func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return false
        }
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            return false
        }
    }

    func unlock() async {
        if await authenticate(reason: String(localized: "解锁 Renewity")) {
            isLocked = false
        }
    }
}

struct AppLockView: View {
    @Environment(AppLockController.self) private var appLock

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "lock.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.accentColor)
            Text("Renewity已锁定")
                .font(.title2.bold())
            Text("使用面容 ID、触控 ID 或设备密码继续。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("解锁") {
                Task { await appLock.unlock() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            Spacer()
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.groupedBackground)
        .task {
            await appLock.unlock()
        }
    }
}
