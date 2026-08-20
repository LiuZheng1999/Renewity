import Foundation
import SwiftUI
import WidgetKit

struct UpcomingEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct UpcomingRenewalProvider: TimelineProvider {
    func placeholder(in context: Context) -> UpcomingEntry {
        UpcomingEntry(date: .now, snapshot: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (UpcomingEntry) -> Void) {
        let snapshot = context.isPreview ? WidgetSnapshot.preview : WidgetDataStore.load()
        completion(UpcomingEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UpcomingEntry>) -> Void) {
        let entry = UpcomingEntry(date: .now, snapshot: WidgetDataStore.load())
        let nextMidnight = Calendar.current.nextDate(
            after: .now,
            matching: DateComponents(hour: 0, minute: 5),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }
}

struct UpcomingRenewalWidget: Widget {
    let kind = "UpcomingRenewalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UpcomingRenewalProvider()) { entry in
            UpcomingRenewalWidgetView(entry: entry)
        }
        .configurationDisplayName("即将续费")
        .description("查看未来两周内即将扣费的订阅。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct UpcomingRenewalWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: UpcomingEntry

    private var items: [WidgetUpcomingItem] {
        Array(entry.snapshot.upcoming.prefix(family == .systemMedium ? 4 : 3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("即将续费")
                    .font(.headline)
                Spacer()
                if entry.snapshot.upcomingCount > 0 {
                    Text(verbatim: "\(entry.snapshot.upcomingCount)")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15), in: Capsule())
                        .foregroundStyle(Color.accentColor)
                }
            }

            if items.isEmpty {
                Spacer(minLength: 0)
                Text("未来两周没有扣费")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            } else {
                VStack(spacing: family == .systemMedium ? 8 : 6) {
                    ForEach(items) { item in
                        upcomingRow(item)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    private func upcomingRow(_ item: WidgetUpcomingItem) -> some View {
        HStack(spacing: 8) {
            Text(String(item.name.prefix(1)))
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Color(hex: item.colorHex).gradient, in: RoundedRectangle(cornerRadius: 6, style: .continuous))

            Text(item.name)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)

            Spacer(minLength: 4)

            if family == .systemMedium {
                Text(WidgetFormatters.currency(item.price, code: item.currencyCode ?? entry.snapshot.currencyCode))
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            Text(WidgetFormatters.billingRelative(item.billingDate))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

private extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let red, green, blue: Double
        if cleaned.count == 6 {
            red = Double((int >> 16) & 0xFF) / 255
            green = Double((int >> 8) & 0xFF) / 255
            blue = Double(int & 0xFF) / 255
        } else {
            red = 0.5
            green = 0.5
            blue = 0.5
        }
        self.init(red: red, green: green, blue: blue)
    }
}

#Preview("即将续费 小", as: .systemSmall) {
    UpcomingRenewalWidget()
} timeline: {
    UpcomingEntry(date: .now, snapshot: .preview)
}

#Preview("即将续费 中", as: .systemMedium) {
    UpcomingRenewalWidget()
} timeline: {
    UpcomingEntry(date: .now, snapshot: .preview)
}
