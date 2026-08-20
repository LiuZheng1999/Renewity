import SwiftUI
import WidgetKit

struct SpendEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct MonthlySpendProvider: TimelineProvider {
    func placeholder(in context: Context) -> SpendEntry {
        SpendEntry(date: .now, snapshot: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (SpendEntry) -> Void) {
        let snapshot = context.isPreview ? WidgetSnapshot.preview : WidgetDataStore.load()
        completion(SpendEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SpendEntry>) -> Void) {
        let entry = SpendEntry(date: .now, snapshot: WidgetDataStore.load())
        let next = Calendar.current.nextDate(
            after: .now,
            matching: DateComponents(minute: 0),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct MonthlySpendWidget: Widget {
    let kind = "MonthlySpendWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MonthlySpendProvider()) { entry in
            MonthlySpendWidgetView(entry: entry)
        }
        .configurationDisplayName("每月开支")
        .description("查看本月订阅总支出和年化费用。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct MonthlySpendWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SpendEntry

    var body: some View {
        switch family {
        case .systemMedium:
            medium
        default:
            small
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(WidgetFormatters.monthTitle())支出")
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.85))
            Spacer(minLength: 0)
            Text(WidgetFormatters.currency(entry.snapshot.monthlyTotal, code: entry.snapshot.currencyCode, approximate: entry.snapshot.isApproximate))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text("\(entry.snapshot.activeCount) 个订阅")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            spendBackground
        }
    }

    private var medium: some View {
        HStack(alignment: .bottom, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(WidgetFormatters.monthTitle())支出")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
                Text(WidgetFormatters.currency(entry.snapshot.monthlyTotal, code: entry.snapshot.currencyCode, approximate: entry.snapshot.isApproximate))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 8) {
                labeledValue("年化", WidgetFormatters.currency(entry.snapshot.yearlyTotal, code: entry.snapshot.currencyCode, approximate: entry.snapshot.isApproximate))
                labeledValue("订阅", String(localized: "\(entry.snapshot.activeCount) 个"))
                labeledValue("即将续费", String(localized: "\(entry.snapshot.upcomingCount) 笔"))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            spendBackground
        }
    }

    private func labeledValue(_ title: LocalizedStringKey, _ value: String) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
    }

    private var spendBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.31, green: 0.27, blue: 0.90),
                Color(red: 0.31, green: 0.27, blue: 0.90).opacity(0.78),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview("每月开支 小", as: .systemSmall) {
    MonthlySpendWidget()
} timeline: {
    SpendEntry(date: .now, snapshot: .preview)
}

#Preview("每月开支 中", as: .systemMedium) {
    MonthlySpendWidget()
} timeline: {
    SpendEntry(date: .now, snapshot: .preview)
}
