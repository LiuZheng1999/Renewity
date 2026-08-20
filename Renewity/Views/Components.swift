import Foundation
import SwiftData
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

extension Color {
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

    static var groupedBackground: Color {
        #if canImport(UIKit)
        Color(.systemGroupedBackground)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }

    static var groupedSecondary: Color {
        #if canImport(UIKit)
        Color(.secondarySystemGroupedBackground)
        #else
        Color(nsColor: .controlBackgroundColor)
        #endif
    }
}

enum BrandArtwork {
    static func exists(_ name: String) -> Bool {
        #if canImport(UIKit)
        UIImage(named: name) != nil
        #elseif canImport(AppKit)
        NSImage(named: name) != nil
        #else
        false
        #endif
    }
}

struct SubscriptionIconView: View {
    let iconName: String
    let color: Color
    var size: CGFloat = 44
    var remoteURL: URL? = nil

    private var cornerRadius: CGFloat { size * 0.2237 }

    var body: some View {
        Group {
            if let stored = storedImage {
                stored
                    .resizable()
                    .scaledToFill()
            } else if BrandArtwork.exists(iconName) {
                Image(iconName)
                    .resizable()
                    .scaledToFill()
            } else if let remoteURL {
                AsyncImage(url: remoteURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .empty:
                        ProgressView()
                    default:
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(.black.opacity(0.08), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.12), radius: size * 0.05, y: size * 0.04)
    }

    private var storedImage: Image? {
        #if canImport(UIKit)
        if let image = ServiceIconStore.uiImage(named: iconName) {
            return Image(uiImage: image)
        }
        #elseif canImport(AppKit)
        if let image = ServiceIconStore.nsImage(named: iconName) {
            return Image(nsImage: image)
        }
        #endif
        return nil
    }

    private var fallback: some View {
        Image(systemName: fallbackSymbol)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(color.gradient)
    }

    private var fallbackSymbol: String {
        iconName.contains(".") || iconName.contains("fill") ? iconName : "creditcard.fill"
    }
}

struct StatChip: View {
    let title: LocalizedStringKey
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)
                .labelStyle(.titleAndIcon)
            Text(value)
                .font(.title3.weight(.semibold))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.groupedSecondary, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct SubscriptionRowView: View {
    let subscription: Subscription
    @Environment(\.appCategories) private var categories

    private var category: AppCategory {
        subscription.resolvedCategory(in: categories)
    }

    var body: some View {
        HStack(spacing: 14) {
            SubscriptionIconView(
                iconName: subscription.iconName,
                color: category.color
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(subscription.name)
                        .font(.headline)
                    if subscription.isInTrial {
                        Text("试用中")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15), in: Capsule())
                    }
                    if !subscription.isActive {
                        Text("已暂停")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.quaternary, in: Capsule())
                    }
                }
                Text(Formatters.eventRelative(for: subscription))
                    .font(.subheadline)
                    .foregroundStyle(subscription.isDueSoon ? Color.orange : Color.secondary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text(Formatters.currency(subscription.price, code: subscription.resolvedCurrencyCode))
                    .font(.headline)
                    .monospacedDigit()
                Text(subscription.cycleDisplayTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .opacity(subscription.isActive ? 1 : 0.55)
    }
}

struct CategorySpendRow: View {
    let item: CategoryTotal
    let total: Decimal
    let currencyCode: String
    var approximate = false

    private var progress: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(NSDecimalNumber(decimal: item.amount / total).doubleValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(item.category.localizedName, systemImage: item.category.iconName)
                    .foregroundStyle(item.category.color)
                Spacer()
                Text(Formatters.currency(item.amount, code: currencyCode, approximate: approximate))
                    .fontWeight(.medium)
                    .monospacedDigit()
            }
            .font(.subheadline)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.12))
                    Capsule()
                        .fill(item.category.color.gradient)
                        .frame(width: max(8, geometry.size.width * progress))
                }
            }
            .frame(height: 8)
        }
    }
}

struct UpcomingWeekStrip: View {
    let subscriptions: [Subscription]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { offset in
                dayColumn(offset)
            }
        }
    }

    private func dayColumn(_ offset: Int) -> some View {
        let date = Calendar.current.date(byAdding: .day, value: offset, to: Calendar.current.startOfDay(for: Date())) ?? Date()
        let count = subscriptions.active.filter {
            Calendar.current.isDate($0.nextRelevantDate, inSameDayAs: date)
        }.count
        let isToday = offset == 0

        return VStack(spacing: 8) {
            Text(Formatters.weekdayShort(date))
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.subheadline.weight(isToday ? .bold : .medium))
            Circle()
                .fill(count > 0 ? Color.accentColor : Color.secondary.opacity(0.15))
                .frame(width: 7, height: 7)
                .overlay {
                    if count > 1 {
                        Text("\(min(count, 9))")
                            .font(.system(size: 6, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            isToday ? Color.accentColor.opacity(0.12) : Color.clear,
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }
}
