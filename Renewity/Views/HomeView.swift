import SwiftData
import SwiftUI

struct HomeView: View {
    @Query(sort: \Subscription.name) private var subscriptions: [Subscription]
    @Environment(\.appCategories) private var categories
    @AppStorage("currencyCode") private var currencyCode = "CNY"
    @AppStorage("heroConvertToOtherCurrency") private var convertToOtherCurrency = true
    @AppStorage("heroConversionCurrencyCode") private var conversionCurrencyCode = "CNY"
    @State private var showingSettings = false
    @State private var showingAdd = false
    @State private var showingPaywall = false
    @State private var showingConversionPicker = false
    @State private var showingHeroOptions = false
    @State private var pendingEnableOtherCurrency = false
    @State private var pendingOpenConversionPicker = false
    @Environment(ProStore.self) private var proStore
    @Environment(ExchangeRateStore.self) private var exchangeRates

    private var upcoming: [Subscription] {
        subscriptions.upcoming(withinDays: 14)
    }

    var body: some View {
        NavigationStack {
            Group {
                if subscriptions.isEmpty {
                    ContentUnavailableView {
                        Label("还没有订阅", systemImage: "creditcard")
                    } description: {
                        Text("把流媒体、云存储和会员都记下来，随时掌握每月要花多少钱。")
                    } actions: {
                        Button("添加订阅") {
                            presentAdd()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    dashboard
                }
            }
            .background(Color.groupedBackground)
            .navigationTitle("概览")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingSettings = true
                    } label: {
                        ProfileAvatarView(size: 32)
                    }
                    .accessibilityLabel("设置")
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingAdd) {
                SubscriptionFormView()
            }
            .sheet(isPresented: $showingPaywall, onDismiss: applyPendingHeroConversionIfPro) {
                PaywallView()
            }
            .sheet(isPresented: $showingConversionPicker) {
                CurrencyPickerView(currencyCode: $conversionCurrencyCode)
            }
        }
    }

    private func presentAdd() {
        if proStore.canAddSubscription(currentCount: subscriptions.count) {
            showingAdd = true
        } else {
            showingPaywall = true
        }
    }

    private var showsOtherCurrencyConversion: Bool {
        convertToOtherCurrency && proStore.isPro
    }

    private var convertToOtherCurrencyBinding: Binding<Bool> {
        Binding(
            get: { showsOtherCurrencyConversion },
            set: { newValue in
                if newValue {
                    requestOtherCurrencyConversion(openPicker: false)
                } else {
                    convertToOtherCurrency = false
                }
            }
        )
    }

    private func requestOtherCurrencyConversion(openPicker: Bool) {
        showingHeroOptions = false
        if proStore.isPro {
            convertToOtherCurrency = true
            if openPicker {
                DispatchQueue.main.async {
                    showingConversionPicker = true
                }
            }
            return
        }
        pendingEnableOtherCurrency = true
        pendingOpenConversionPicker = openPicker
        DispatchQueue.main.async {
            showingPaywall = true
        }
    }

    private func applyPendingHeroConversionIfPro() {
        let shouldEnable = pendingEnableOtherCurrency
        let shouldOpenPicker = pendingOpenConversionPicker
        pendingEnableOtherCurrency = false
        pendingOpenConversionPicker = false
        guard proStore.isPro, shouldEnable || shouldOpenPicker else { return }
        if shouldEnable {
            convertToOtherCurrency = true
        }
        if shouldOpenPicker {
            DispatchQueue.main.async {
                showingConversionPicker = true
            }
        }
    }

    private var dashboard: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroCard
                miniStats
                weekCard
                upcomingCard
                categoryCard
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .scrollDisabled(showingHeroOptions)
        .overlayPreferenceValue(HeroOptionsAnchorKey.self) { anchor in
            GeometryReader { geo in
                if showingHeroOptions, let anchor {
                    let r = geo[anchor]
                    let panelWidth: CGFloat = 280
                    let x = min(max(8, r.maxX - panelWidth), geo.size.width - panelWidth - 8)
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { showingHeroOptions = false }
                        .overlay(alignment: .topLeading) {
                            heroOptionsPanel
                                .frame(width: panelWidth)
                                .offset(x: x, y: r.maxY + 6)
                        }
                }
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text("本月支出")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.92))
                Spacer(minLength: 8)
                Button {
                    showingHeroOptions.toggle()
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("本月支出选项")
                .anchorPreference(key: HeroOptionsAnchorKey.self, value: .bounds) { $0 }
            }

            Spacer(minLength: 10)

            HStack(alignment: .center, spacing: 12) {
                Text(monthlyPrimaryText)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                    .layoutPriority(1)

                if showsOtherCurrencyConversion {
                    conversionLabel(monthlyConversionText)
                        .layoutPriority(0)
                }

                Spacer(minLength: 0)
            }

            Spacer(minLength: 10)

            Text(yearlyLineText)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .contentTransition(.numericText())

            if defaultMonthlySpend.hasFailures {
                Text(conversionFailureText)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.78))
                    .padding(.top, 6)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .aspectRatio(2, contentMode: .fit)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.accentColor,
                            Color.accentColor.mix(with: .white, by: 0.28),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
    }

    @ViewBuilder
    private func conversionLabel(_ text: String) -> some View {
        let label = Text(text)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white.opacity(0.92))
            .lineLimit(2)
            .minimumScaleFactor(0.8)
            .multilineTextAlignment(.leading)

        if hasConversionTarget {
            label
        } else {
            Button {
                requestOtherCurrencyConversion(openPicker: true)
            } label: {
                label
            }
            .buttonStyle(.plain)
        }
    }

    private var miniStats: some View {
        HStack(spacing: 12) {
            StatChip(
                title: "活跃订阅",
                value: String(localized: "\(subscriptions.active.count) 个"),
                systemImage: "rectangle.stack.fill"
            )
            StatChip(
                title: "两周内续费",
                value: String(localized: "\(upcoming.count) 笔"),
                systemImage: "calendar"
            )
        }
    }

    private var weekCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("近 7 天")
                .font(.headline)
            UpcomingWeekStrip(subscriptions: subscriptions)
        }
        .padding(16)
        .background(Color.groupedSecondary, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private var upcomingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("即将续费")
                .font(.headline)

            if upcoming.isEmpty {
                Text("未来两周没有扣费")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ForEach(upcoming.prefix(5)) { subscription in
                    NavigationLink {
                        SubscriptionDetailView(subscription: subscription)
                    } label: {
                        HStack(spacing: 12) {
                            SubscriptionIconView(
                                iconName: subscription.iconName,
                                color: subscription.resolvedCategory(in: categories).color,
                                size: 36
                            )
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(subscription.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    if subscription.isInTrial {
                                        Text("试用中")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(.orange)
                                    }
                                }
                                Text(Formatters.eventRelative(for: subscription))
                                    .font(.caption)
                                    .foregroundStyle(subscription.isDueSoon ? Color.orange : Color.secondary)
                            }
                            Spacer()
                            Text(Formatters.currency(subscription.price, code: subscription.resolvedCurrencyCode))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .monospacedDigit()
                        }
                    }
                    .buttonStyle(.plain)

                    if subscription.id != upcoming.prefix(5).last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .background(Color.groupedSecondary, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private var categoryCard: some View {
        let totals = convertedCategoryTotals
        VStack(alignment: .leading, spacing: 16) {
            Text("分类支出")
                .font(.headline)

            if totals.isEmpty {
                Text("暂无分类数据")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(totals) { item in
                    CategorySpendRow(
                        item: item,
                        total: convertedMonthlyTotal,
                        currencyCode: currencyCode,
                        approximate: usesConversion
                    )
                }
            }
        }
        .padding(16)
        .background(Color.groupedSecondary, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var usesConversion: Bool {
        subscriptions.needsCurrencyConversion(to: currencyCode)
    }

    private var defaultMonthlySpend: CurrencyConversionResult {
        subscriptions.convertedMonthlySpend(to: currencyCode, using: exchangeRates)
    }

    private var convertedMonthlyTotal: Decimal {
        defaultMonthlySpend.amount
    }

    private var conversionFailureText: String {
        String(localized: "有 \(defaultMonthlySpend.failedCount) 笔金额暂时无法换算，未计入合计。")
    }

    private var convertedCategoryTotals: [CategoryTotal] {
        subscriptions.convertedCategoryTotals(
            using: categories,
            displayCode: currencyCode,
            rates: exchangeRates
        )
    }

    private var hasConversionTarget: Bool {
        showsOtherCurrencyConversion
            && conversionCurrencyCode.uppercased() != currencyCode.uppercased()
    }

    private var monthlyPrimaryText: String {
        Formatters.currency(convertedMonthlyTotal, code: currencyCode)
    }

    private var monthlyConversionText: String {
        guard hasConversionTarget else {
            return String(localized: "换算为其他货币")
        }
        return Formatters.currency(
            subscriptions.convertedMonthlySpend(to: conversionCurrencyCode, using: exchangeRates).amount,
            code: conversionCurrencyCode,
            approximate: true
        )
    }

    private var yearlyLineText: String {
        let yearly = Formatters.currency(
            subscriptions.convertedYearlySpend(to: currencyCode, using: exchangeRates).amount,
            code: currencyCode
        )
        guard showsOtherCurrencyConversion else {
            return String(localized: "年化 \(yearly)")
        }
        if hasConversionTarget {
            let converted = Formatters.currency(
                subscriptions.convertedYearlySpend(to: conversionCurrencyCode, using: exchangeRates).amount,
                code: conversionCurrencyCode,
                approximate: true
            )
            return String(localized: "年化 \(yearly) | \(converted)")
        }
        return String(localized: "年化 \(yearly) | 换算为其他货币")
    }

    private var heroOptionsPanel: some View {
        VStack(spacing: 0) {
            Toggle("换算为其他货币", isOn: convertToOtherCurrencyBinding)
                .toggleStyle(.switch)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            if showsOtherCurrencyConversion {
                Divider()
                Button("选择货币") {
                    requestOtherCurrencyConversion(openPicker: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 16, y: 8)
    }
}

private struct HeroOptionsAnchorKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>?

    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue() ?? value
    }
}

#Preview {
    HomeView()
        .modelContainer(PreviewContainer.sample)
        .environment(ProStore())
        .environment(ExchangeRateStore())
}
