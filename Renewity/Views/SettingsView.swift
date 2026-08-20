import StoreKit
import SwiftData
import SwiftUI
import PhotosUI

struct SettingsView: View {
    @AppStorage(ProfileAvatarStore.revisionKey) private var avatarRevision = 0
    @Environment(\.dismiss) private var dismiss
    @Environment(ProStore.self) private var proStore
    @Environment(\.requestReview) private var requestReview
    @Environment(\.openURL) private var openURL
    @State private var showingPaywall = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var cropperItem: AvatarCropItem?

    var body: some View {
        NavigationStack {
            Form {
                profileSection
                proSection

                Section("通用") {
                    NavigationLink {
                        AppearanceSettingsView()
                    } label: {
                        rowLabel("外观", systemImage: "circle.lefthalf.filled")
                    }
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        rowLabel("通知", systemImage: "bell")
                    }
                    NavigationLink {
                        CurrencySettingsView()
                    } label: {
                        rowLabel("币种", systemImage: "yensign.circle")
                    }
                    NavigationLink {
                        CategoryManageView()
                    } label: {
                        rowLabel("分类", systemImage: "folder")
                    }
                }

                Section("数据") {
                    NavigationLink {
                        BackupSettingsView()
                    } label: {
                        rowLabel("数据备份", systemImage: "icloud")
                    }
                }

                Section("隐私与安全") {
                    NavigationLink {
                        PrivacySecurityView()
                    } label: {
                        rowLabel("隐私与安全", systemImage: "lock.shield")
                    }
                }

                Section("法律") {
                    NavigationLink {
                        LegalDocumentView(document: .termsOfUse)
                    } label: {
                        rowLabel("用户协议", systemImage: "doc.plaintext")
                    }
                    NavigationLink {
                        LegalDocumentView(document: .privacyPolicy)
                    } label: {
                        rowLabel("隐私政策", systemImage: "doc.text")
                    }
                }

                Section("支持") {
                    mailRow("报告问题", systemImage: "exclamationmark.bubble", subject: String(localized: "问题报告"), extra: deviceInfo)
                    mailRow("联系支持", systemImage: "envelope", subject: String(localized: "支持请求"))
                    mailRow("分享反馈", systemImage: "text.bubble", subject: String(localized: "产品反馈"))
                    mailRow("功能建议", systemImage: "lightbulb", subject: String(localized: "功能建议"))
                }

                Section("关注我们") {
                    socialRow("Instagram", url: AppConfig.instagramURL) {
                        InstagramMark()
                    }
                    socialRow("X", url: AppConfig.xURL) {
                        XSocialMark()
                    }
                }

                Section("更多") {
                    NavigationLink {
                        AboutView()
                    } label: {
                        rowLabel("关于", systemImage: "info.circle")
                    }
                    Button {
                        requestReview()
                        if let url = AppConfig.appStoreWriteReviewURL {
                            openURL(url)
                        }
                    } label: {
                        rowLabel("在 App Store 评分", systemImage: "star")
                    }
                    .foregroundStyle(.primary)
                    ShareLink(item: AppConfig.shareMessage) {
                        rowLabel("推荐给朋友", systemImage: "square.and.arrow.up")
                    }
                    .foregroundStyle(.primary)
                }
            }
            .navigationTitle("设置")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .fullScreenCover(item: $cropperItem) { item in
                ImageCropView(
                    sourceImage: item.image,
                    onCancel: { cropperItem = nil },
                    onComplete: { cropped in
                        ProfileAvatarStore.save(cropped)
                        cropperItem = nil
                    }
                )
            }
            .onChange(of: pickerItem) { _, item in
                guard let item else { return }
                Task {
                    defer { pickerItem = nil }
                    guard let data = try? await item.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else { return }
                    let prepared = ImageCropView.preparedSource(image)
                    try? await Task.sleep(for: .milliseconds(350))
                    await MainActor.run {
                        cropperItem = AvatarCropItem(image: prepared)
                    }
                }
            }
        }
    }

    private var profileSection: some View {
        Section {
            HStack(spacing: 14) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    HStack(spacing: 14) {
                        ProfileAvatarView(size: 64)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("自定义头像")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(hasCustomAvatar ? String(localized: "轻点更换照片") : String(localized: "从相册选择照片"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .foregroundStyle(.primary)
                Spacer(minLength: 8)
                if hasCustomAvatar {
                    Button("移除头像", role: .destructive) {
                        ProfileAvatarStore.remove()
                    }
                }
            }
            .padding(.vertical, 6)
        } header: {
            Text("个人资料")
        }
    }

    private var hasCustomAvatar: Bool {
        _ = avatarRevision
        return ProfileAvatarStore.hasAvatar
    }

    @ViewBuilder
    private var proSection: some View {
        Section {
            if proStore.isPro {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Renewity Pro")
                            .font(.headline)
                        Text("已解锁全部功能")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(Color.accentColor)
                }
            } else {
                Button {
                    showingPaywall = true
                } label: {
                    HStack {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("升级到 Pro")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("无限订阅、多货币和云备份")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(Color.accentColor)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .foregroundStyle(.primary)
            }
        }
    }

    private var deviceInfo: String {
        """

        ———
        \(String(localized: "应用"))：\(AppConfig.appName) \(AppConfig.versionText)
        """
    }

    private func rowLabel(_ title: LocalizedStringKey, systemImage: String) -> some View {
        rowLabel(title) {
            Image(systemName: systemImage)
                .symbolRenderingMode(.hierarchical)
        }
    }

    private func rowLabel<Icon: View>(_ title: LocalizedStringKey, @ViewBuilder icon: () -> Icon) -> some View {
        Label {
            Text(title)
                .foregroundStyle(.primary)
        } icon: {
            icon()
                .foregroundStyle(Color.accentColor)
        }
    }

    private func socialRow<Icon: View>(
        _ title: LocalizedStringKey,
        url: URL,
        @ViewBuilder icon: () -> Icon
    ) -> some View {
        Button {
            openURL(url)
        } label: {
            rowLabel(title, icon: icon)
        }
        .foregroundStyle(.primary)
    }

    private func mailRow(_ title: LocalizedStringKey, systemImage: String, subject: String, extra: String = "") -> some View {
        Button {
            if let url = mailURL(subject: "\(AppConfig.appName) \(subject)", body: extra) {
                openURL(url)
            }
        } label: {
            rowLabel(title, systemImage: systemImage)
        }
        .foregroundStyle(.primary)
    }

    private func mailURL(subject: String, body: String) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = AppConfig.supportEmail
        components.queryItems = [
            .init(name: "subject", value: subject),
            .init(name: "body", value: body),
        ]
        return components.url
    }
}

private struct InstagramMark: View {
    var body: some View {
        Canvas { context, size in
            let inset = size.width * 0.08
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset)
            let line = max(1.4, size.width * 0.09)
            let outline = Path(roundedRect: rect, cornerRadius: size.width * 0.28)
            context.stroke(outline, with: .foreground, lineWidth: line)

            let lens = CGRect(
                x: size.width * 0.29,
                y: size.height * 0.29,
                width: size.width * 0.42,
                height: size.height * 0.42
            )
            context.stroke(Path(ellipseIn: lens), with: .foreground, lineWidth: line)

            let dotSize = size.width * 0.12
            let dot = CGRect(
                x: size.width * 0.64,
                y: size.height * 0.22,
                width: dotSize,
                height: dotSize
            )
            context.fill(Path(ellipseIn: dot), with: .foreground)
        }
        .frame(width: 20, height: 20)
        .accessibilityHidden(true)
    }
}

private struct XSocialMark: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            var path = Path()
            path.move(to: CGPoint(x: w * 0.10, y: h * 0.12))
            path.addLine(to: CGPoint(x: w * 0.44, y: h * 0.50))
            path.addLine(to: CGPoint(x: w * 0.10, y: h * 0.88))
            path.addLine(to: CGPoint(x: w * 0.26, y: h * 0.88))
            path.addLine(to: CGPoint(x: w * 0.50, y: h * 0.58))
            path.addLine(to: CGPoint(x: w * 0.90, y: h * 0.88))
            path.addLine(to: CGPoint(x: w * 0.90, y: h * 0.68))
            path.addLine(to: CGPoint(x: w * 0.58, y: h * 0.42))
            path.addLine(to: CGPoint(x: w * 0.86, y: h * 0.12))
            path.addLine(to: CGPoint(x: w * 0.70, y: h * 0.12))
            path.addLine(to: CGPoint(x: w * 0.46, y: h * 0.38))
            path.addLine(to: CGPoint(x: w * 0.26, y: h * 0.12))
            path.closeSubpath()
            context.fill(path, with: .foreground)
        }
        .frame(width: 18, height: 18)
        .accessibilityHidden(true)
    }
}

private struct AvatarCropItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

#Preview {
    SettingsView()
        .environment(ProStore())
        .environment(AppLockController())
        .environment(ExchangeRateStore())
        .modelContainer(PreviewContainer.sample)
}
