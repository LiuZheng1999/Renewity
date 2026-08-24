import SwiftData
import SwiftUI
import Charts

struct HomeView: View {
    @Query(sort: \Subscription.name) private var subscriptions: [Subscription]
    @Environment(\.appCategories) private var categories
    @AppStorage("currencyCode") private var currencyCode = "CNY"
    @AppStorage("heroConversionCurrencyCode") private var conversionCurrencyCode = ""
    @AppStorage("heroConversionCurrencyChosen") private var conversionCurrencyChosen = false
    @State private var showingSettings = false
    @State private var showingAdd = false
    @State private var showingPaywall = false
    @State private var showingConversionPicker = false
    @State private var pendingConversionCurrencyCode: String?
    @State private var heroShowsConverted = false
    @State private var heroAmountsOpaque = true
    @State private var isTogglingHeroCurrency = false
    @Environment(ProStore.self) private var proStore
    @Environment(ExchangeRateStore.self) private var exchangeRates
    @Environment(\.mainTab) private var mainTab

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
            .appSkyBackground()
            .navigationTitle("概览")
            .toolbarTitleDisplayMode(.inlineLarge)
            .skyNavigationChrome()
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
            .fullScreenCover(isPresented: $showingPaywall, onDismiss: applyPendingConversionIfPro) {
                PaywallView()
            }
            .sheet(isPresented: $showingConversionPicker, onDismiss: presentPaywallIfConversionLocked) {
                CurrencyPickerView(
                    currencyCode: Binding(
                        get: { selectedConversionCurrencyCode ?? "" },
                        set: { conversionCurrencyCode = $0 }
                    ),
                    onSelect: handleConversionCurrencySelect,
                    excludedCodes: [currencyCode.uppercased()]
                )
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

    private var dashboard: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroCard
                weekCard
                upcomingCard
                categoryCard
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
    }

    private var heroCard: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: toggleHeroCurrency) {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("年均支出")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.78))
                        yearlyAmountLabel
                    }

                    HStack(alignment: .top, spacing: 10) {
                        heroMetric(
                            title: "本年剩余支出",
                            value: showsConversionPlaceholder ? "—" : remainingYearText,
                            valueOpacity: heroAmountsOpaque ? 1 : 0
                        )
                        heroMetric(title: "活跃订阅", value: String(localized: "\(subscriptions.active.count) 笔"))
                        heroMetric(title: "两周内到期", value: String(localized: "\(upcoming.count) 笔"))
                    }
                }
                .padding(22)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .background {
                    HeroCardBackground()
                }
            }
            .buttonStyle(.plain)
            .accessibilityHint(showsConversionPlaceholder ? "选择第二种货币" : "切换年均支出和本年剩余支出的货币")
            .overlay(alignment: .bottomTrailing) {
                heroPageControl
                    .padding(.trailing, 16)
                    .padding(.bottom, 14)
                    .allowsHitTesting(false)
            }

            NavigationLink {
                SpendMetricsInfoView()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.78))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("关于数值")
            .accessibilityHint("查看年均支出、本年剩余支出和日历金额的说明")
            .padding(.top, 6)
            .padding(.trailing, 6)
        }
    }

    @ViewBuilder
    private var yearlyAmountLabel: some View {
        if showsConversionPlaceholder {
            Text("选择货币")
                .font(.title.weight(.semibold))
                .foregroundStyle(.white.opacity(0.5))
                .contentTransition(.opacity)
                .opacity(heroAmountsOpaque ? 1 : 0)
        } else {
            Text(yearlyPrimaryText)
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .contentTransition(.opacity)
                .opacity(heroAmountsOpaque ? 1 : 0)
        }
    }

    private var heroPageControl: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(.white.opacity(heroShowsConverted ? 0.32 : 1))
                .frame(width: 6, height: 6)
            Circle()
                .fill(.white.opacity(heroShowsConverted ? 1 : 0.32))
                .frame(width: 6, height: 6)
        }
        .animation(.easeInOut(duration: 0.2), value: heroShowsConverted)
        .accessibilityHidden(true)
    }

    private func toggleHeroCurrency() {
        guard !isTogglingHeroCurrency else { return }
        isTogglingHeroCurrency = true
        Task { @MainActor in
            withAnimation(.easeOut(duration: 0.18)) {
                heroAmountsOpaque = false
            }
            try? await Task.sleep(for: .milliseconds(180))
            heroShowsConverted.toggle()
            withAnimation(.easeIn(duration: 0.22)) {
                heroAmountsOpaque = true
            }
            try? await Task.sleep(for: .milliseconds(220))
            isTogglingHeroCurrency = false
            if showsConversionPlaceholder {
                showingConversionPicker = true
            }
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

    private func presentPaywallIfConversionLocked() {
        guard pendingConversionCurrencyCode != nil, !proStore.isPro else { return }
        DispatchQueue.main.async {
            showingPaywall = true
        }
    }

    private func applyPendingConversionIfPro() {
        guard let pendingConversionCurrencyCode else { return }
        if proStore.isPro {
            applyConversionCurrency(pendingConversionCurrencyCode)
        }
        self.pendingConversionCurrencyCode = nil
    }

    private func applyConversionCurrency(_ code: String) {
        conversionCurrencyCode = code
        conversionCurrencyChosen = true
    }

    private func heroMetric(title: LocalizedStringKey, value: String, valueOpacity: Double = 1) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.62))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .monospacedDigit()
                .contentTransition(.opacity)
                .opacity(valueOpacity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var weekCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                mainTab.wrappedValue = .calendar
            } label: {
                HStack {
                    Text("近 7 天")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.35), radius: 1.5, y: 0.5)
                }
            }
            .buttonStyle(.plain)
            .accessibilityHint("查看日历")
            UpcomingWeekStrip(subscriptions: subscriptions)
        }
        .padding(16)
        .background(Color.groupedSecondary, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private var upcomingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("即将续订")
                .font(.headline)

            if upcoming.isEmpty {
                Text("未来两周没有付款")
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
                HStack(alignment: .center, spacing: 20) {
                    Chart(totals) { item in
                        SectorMark(
                            angle: .value("金额", NSDecimalNumber(decimal: item.amount).doubleValue),
                            innerRadius: .ratio(0.58),
                            angularInset: 1.6
                        )
                        .foregroundStyle(item.category.color)
                        .cornerRadius(3)
                    }
                    .chartLegend(.hidden)
                    .frame(width: 148, height: 148)
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(totals) { item in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(item.category.color)
                                    .frame(width: 8, height: 8)
                                Text(item.category.localizedName)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                Spacer(minLength: 4)
                                Text(Formatters.currency(item.amount, code: currencyCode, approximate: usesConversion))
                                    .font(.caption.weight(.medium))
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.groupedSecondary, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var usesConversion: Bool {
        subscriptions.needsCurrencyConversion(to: currencyCode)
    }

    private var selectedConversionCurrencyCode: String? {
        guard conversionCurrencyChosen else { return nil }
        return AppConfig.selectedCurrencyCode(from: conversionCurrencyCode)
    }

    private var showsConversionPlaceholder: Bool {
        heroShowsConverted && selectedConversionCurrencyCode == nil
    }

    private var heroCurrencyCode: String {
        if heroShowsConverted, let selectedConversionCurrencyCode {
            return selectedConversionCurrencyCode
        }
        return currencyCode
    }

    private var convertedYearlySpend: CurrencyConversionResult {
        subscriptions.convertedYearlySpend(to: heroCurrencyCode, using: exchangeRates)
    }

    private var yearlyPrimaryText: String {
        Formatters.currency(convertedYearlySpend.amount, code: heroCurrencyCode)
    }

    private var remainingYearText: String {
        Formatters.currency(
            remainingYearSpend,
            code: heroCurrencyCode,
            approximate: subscriptions.needsCurrencyConversion(to: heroCurrencyCode)
        )
    }

    private var remainingYearSpend: Decimal {
        subscriptions.convertedRemainingYearSpend(to: heroCurrencyCode, using: exchangeRates).amount
    }

    private var convertedCategoryTotals: [CategoryTotal] {
        subscriptions.convertedCategoryTotals(
            using: categories,
            displayCode: currencyCode,
            rates: exchangeRates
        )
    }
}

private struct SpendMetricsInfoView: View {
    var body: some View {
        List {
            Section {
                Label {
                    Text("一次性订阅不计入这些指标。日历上仍会显示圆点，但不会加入金额。")
                } icon: {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                }
                .accessibilityElement(children: .combine)
            }

            Section("概览") {
                metricRow(
                    title: "年均支出",
                    detail: "如果每笔自动续订的订阅都按今天的价格再付满一年，就是年均支出。各周期会先换成每月金额，再乘以 12。已暂停、试用中还没首次付款的不计入。"
                )
                metricRow(
                    title: "本年剩余支出",
                    detail: "从今天起到今年 12 月 31 日，这些自动续订的订阅实际还会付款几次，把这几次的金额加起来。年内已经付过、不会再付的不计入。"
                )
            }

            Section("日历") {
                metricRow(
                    title: "总计",
                    detail: "当前查看的月份里，所有自动续订金额之和，包括本月已经过去的日子。"
                )
                metricRow(
                    title: "即将到来",
                    detail: "当前查看的月份里，从今天（含今天）到月底还会发生的自动续订金额之和。查看过去的月份时为 0；查看未来的月份时与总计相同。"
                )
            }
        }
        .navigationTitle("关于数值")
        .toolbarTitleDisplayMode(.inline)
    }

    private func metricRow(title: LocalizedStringKey, detail: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

private struct HeroCardBackground: View {
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)

        GeometryReader { geo in
            Image("HeroBackground")
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
        .clipShape(shape)
    }
}

private struct CurrencyMonthlySpendView: View {
    let rows: [CurrencyMonthlySpend]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if rows.isEmpty {
                        Text("当前没有计入月支出的订阅")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(rows) { row in
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(Formatters.currencyFullName(for: row.code))
                                    Text("\(row.code) · \(row.count) 笔")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 8)
                                Text(Formatters.currency(row.amount, code: row.code))
                                    .font(.body.weight(.semibold))
                                    .monospacedDigit()
                                    .multilineTextAlignment(.trailing)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                } footer: {
                    Text("按每笔订阅的付款币种，把周期费用折成每月后直接相加，不做汇率换算。试用中还没首次付款的不计入。")
                }
            }
            .navigationTitle("各币种月支出")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(PreviewContainer.sample)
        .environment(ProStore())
        .environment(ExchangeRateStore())
}
