import SwiftUI

struct WelcomeView: View {
    @AppStorage("hasCompletedWelcome") private var hasCompletedWelcome = false
    @State private var page = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                introPage.tag(0)
                insightPage.tag(1)
                reminderPage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            VStack(spacing: 12) {
                Button {
                    if page < 2 {
                        withAnimation { page += 1 }
                    } else {
                        hasCompletedWelcome = true
                    }
                } label: {
                    Text(page == 2 ? String(localized: "开始使用") : String(localized: "继续"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                if page < 2 {
                    Button("跳过") {
                        hasCompletedWelcome = true
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .background(Color.groupedBackground)
    }

    private var introPage: some View {
        VStack(spacing: 28) {
            Spacer()
            logoCollage
            VStack(spacing: 10) {
                Text("欢迎使用 Renewity")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text("把 Netflix、Spotify、ChatGPT 这些订阅都放在一起，随时看清每个月要花多少钱。")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
            Spacer()
        }
        .padding(.horizontal, 28)
    }

    private var insightPage: some View {
        welcomeLayout(
            systemImage: "chart.pie.fill",
            title: "看清每一笔固定支出",
            subtitle: "按分类统计月费和年均支出，马上知道哪些订阅最贵，哪些可以砍掉。"
        )
    }

    private var reminderPage: some View {
        welcomeLayout(
            systemImage: "bell.badge.fill",
            title: "续订前提醒你",
            subtitle: "在付款前一天收到通知，避免忘了取消，也不用再翻邮件找账单。"
        )
    }

    private func welcomeLayout(systemImage: String, title: LocalizedStringKey, subtitle: LocalizedStringKey) -> some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: systemImage)
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(Color.accentColor.gradient)
                .frame(width: 120, height: 120)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 32, style: .continuous))
            VStack(spacing: 10) {
                Text(title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            Spacer()
        }
        .padding(.horizontal, 28)
    }

    private var logoCollage: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4), spacing: 14) {
            ForEach(SubscriptionTemplate.featuredLogoIDs, id: \.self) { logoID in
                SubscriptionIconView(
                    iconName: "logo_\(logoID)",
                    color: .accentColor,
                    size: 64
                )
            }
        }
        .padding(.horizontal, 8)
    }
}

#Preview {
    WelcomeView()
}
