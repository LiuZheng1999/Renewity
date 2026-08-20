import SwiftData
import SwiftUI

struct CalendarView: View {
    @Query(sort: \Subscription.name) private var subscriptions: [Subscription]
    @Environment(\.appCategories) private var categories
    @Environment(ExchangeRateStore.self) private var exchangeRates
    @AppStorage("currencyCode") private var currencyCode = "CNY"

    @State private var visibleMonth = Calendar.current.startOfDay(for: Date())
    @State private var selectedDay: CalendarDaySelection?

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.bottom, 28)
                    weekdayHeader
                    calendarGrid
                        .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 28)
            }
            .background(Color.groupedBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $selectedDay) { day in
                CalendarDaySheet(date: day.date, items: day.items)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                Text(monthTitle)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.primary)

                Spacer(minLength: 8)

                monthStepper
            }

            HStack(spacing: 18) {
                Text(String(localized: "\(totalText) 总计"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)

                Text(String(localized: "\(upcomingText) 即将到来"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var monthStepper: some View {
        HStack(spacing: 4) {
            if !calendar.isDate(visibleMonth, equalTo: Date(), toGranularity: .month) {
                Button("今天") {
                    visibleMonth = calendar.startOfDay(for: Date())
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.accentColor)
                .padding(.trailing, 4)
            }

            Button {
                shiftMonth(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("上个月")

            Button {
                shiftMonth(1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("下个月")
        }
        .foregroundStyle(.primary)
        .buttonStyle(.plain)
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(monthCells.enumerated()), id: \.offset) { _, date in
                CalendarDayCell(
                    date: date,
                    isToday: date.map { calendar.isDateInToday($0) } ?? false,
                    items: date.map { items(on: $0) } ?? []
                ) {
                    guard let date else { return }
                    let dayItems = items(on: date)
                    guard !dayItems.isEmpty else { return }
                    selectedDay = CalendarDaySelection(date: date, items: dayItems)
                }
            }
        }
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    }

    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }

    private var monthTitle: String {
        let now = Date()
        if calendar.isDate(visibleMonth, equalTo: now, toGranularity: .year) {
            return Formatters.monthTitle(visibleMonth)
        }
        return visibleMonth.formatted(.dateTime.year().month(.wide).locale(.autoupdatingCurrent))
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let start = max(0, calendar.firstWeekday - 1)
        return Array(symbols[start...] + symbols[..<start])
    }

    private var monthCells: [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: visibleMonth) else { return [] }
        let first = calendar.startOfDay(for: interval.start)
        let weekday = calendar.component(.weekday, from: first)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        let dayCount = calendar.range(of: .day, in: .month, for: first)?.count ?? 0
        let total = Int(ceil(Double(leading + dayCount) / 7.0) * 7)

        return (0..<total).map { index in
            let day = index - leading + 1
            guard day >= 1, day <= dayCount else { return nil }
            return calendar.date(byAdding: .day, value: day - 1, to: first)
        }
    }

    private var monthCharges: [CalendarCharge] {
        subscriptions.flatMap { subscription in
            subscription.chargeDates(inMonthOf: visibleMonth, calendar: calendar).map {
                CalendarCharge(date: $0, subscription: subscription)
            }
        }
    }

    private var totalAmount: Decimal {
        monthCharges.reduce(0) { $0 + convertedPrice(of: $1.subscription) }
    }

    private var upcomingAmount: Decimal {
        let today = calendar.startOfDay(for: Date())
        return monthCharges.reduce(0) { partial, charge in
            guard charge.date >= today else { return partial }
            return partial + convertedPrice(of: charge.subscription)
        }
    }

    private var totalText: String {
        Formatters.currency(totalAmount, code: currencyCode, approximate: usesConversion)
    }

    private var upcomingText: String {
        Formatters.currency(upcomingAmount, code: currencyCode, approximate: usesConversion)
    }

    private var usesConversion: Bool {
        monthCharges.contains { $0.subscription.resolvedCurrencyCode != currencyCode.uppercased() }
    }

    private func items(on date: Date) -> [CalendarCharge] {
        monthCharges
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.subscription.name.localizedCompare($1.subscription.name) == .orderedAscending }
    }

    private func convertedPrice(of subscription: Subscription) -> Decimal {
        exchangeRates.convert(
            subscription.price,
            from: subscription.resolvedCurrencyCode,
            to: currencyCode
        ) ?? 0
    }

    private func shiftMonth(_ value: Int) {
        if let date = calendar.date(byAdding: .month, value: value, to: visibleMonth) {
            visibleMonth = calendar.startOfDay(for: date)
        }
    }
}

private struct CalendarCharge: Identifiable {
    var id: String { "\(subscription.id.uuidString)-\(date.timeIntervalSinceReferenceDate)" }
    let date: Date
    let subscription: Subscription
}

private struct CalendarDaySelection: Identifiable {
    var id: Date { date }
    let date: Date
    let items: [CalendarCharge]
}

private struct CalendarDayCell: View {
    let date: Date?
    let isToday: Bool
    let items: [CalendarCharge]
    let onTap: () -> Void

    @Environment(\.appCategories) private var categories

    var body: some View {
        Group {
            if date == nil {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .aspectRatio(0.58, contentMode: .fit)
                    .accessibilityHidden(true)
            } else {
                Button(action: onTap) {
                    VStack(alignment: .leading, spacing: 6) {
                        if let date {
                            Text(dayText(date))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(isToday ? Color.white.opacity(0.92) : .primary)
                        }

                        Spacer(minLength: 0)

                        iconCluster
                            .frame(maxWidth: .infinity)

                        Spacer(minLength: 4)
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 6)
                    .padding(.bottom, 8)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(0.58, contentMode: .fit)
                    .background(cellBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(items.isEmpty)
                .accessibilityLabel(accessibilityLabel)
            }
        }
    }

    @ViewBuilder
    private var iconCluster: some View {
        let visible = Array(items.prefix(2))
        if !visible.isEmpty {
            ZStack {
                ForEach(Array(visible.enumerated()), id: \.element.id) { index, item in
                    SubscriptionIconView(
                        iconName: item.subscription.iconName,
                        color: item.subscription.resolvedCategory(in: categories).color,
                        size: 26
                    )
                    .offset(x: CGFloat(index) * 8)
                }

                if items.count > 2 {
                    Text(verbatim: "+\(items.count - 2)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(isToday ? .white : .secondary)
                        .offset(x: 18, y: 12)
                }
            }
            .padding(.trailing, visible.count > 1 ? 8 : 0)
        }
    }

    private var cellBackground: Color {
        if isToday {
            Color.accentColor
        } else {
            Color.groupedSecondary
        }
    }

    private func dayText(_ date: Date) -> String {
        "\(Calendar.current.component(.day, from: date))"
    }

    private var accessibilityLabel: String {
        guard let date else { return "" }
        let day = date.formatted(.dateTime.month().day())
        if items.isEmpty {
            return day
        }
        let names = items.map(\.subscription.name).joined(separator: "、")
        return String(localized: "\(day)，\(names)")
    }
}

private struct CalendarDaySheet: View {
    let date: Date
    let items: [CalendarCharge]
    @Environment(\.appCategories) private var categories
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(items) { item in
                NavigationLink {
                    SubscriptionDetailView(subscription: item.subscription)
                } label: {
                    HStack(spacing: 12) {
                        SubscriptionIconView(
                            iconName: item.subscription.iconName,
                            color: item.subscription.resolvedCategory(in: categories).color,
                            size: 36
                        )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.subscription.name)
                                .font(.subheadline.weight(.semibold))
                            Text(item.subscription.cycleDisplayTitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(Formatters.currency(item.subscription.price, code: item.subscription.resolvedCurrencyCode))
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                    }
                }
            }
            .navigationTitle(date.formatted(.dateTime.month(.wide).day().locale(.autoupdatingCurrent)))
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    CalendarView()
        .modelContainer(PreviewContainer.sample)
        .environment(ProStore())
        .environment(ExchangeRateStore())
}
