import Foundation
import SwiftData
import SwiftUI

@Model
final class AppCategory {
    var identifier: String = UUID().uuidString
    var name: String = ""
    var iconName: String = "tag.fill"
    var colorHex: String = "5E5CE6"
    var isBuiltIn: Bool = false
    var sortOrder: Int = 0
    var createdAt: Date = Date()

    var color: Color {
        Color(hex: colorHex)
    }

    var localizedName: String {
        if isBuiltIn, let preset = SubscriptionCategory(rawValue: identifier) {
            return preset.title
        }
        return name
    }

    init(
        identifier: String = UUID().uuidString,
        name: String,
        iconName: String,
        colorHex: String,
        isBuiltIn: Bool = false,
        sortOrder: Int = 0
    ) {
        self.identifier = identifier
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.isBuiltIn = isBuiltIn
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }

    static func resolve(_ identifier: String, in categories: [AppCategory]) -> AppCategory {
        if let match = categories.first(where: { $0.identifier == identifier }) {
            return match
        }
        if let other = categories.first(where: { $0.identifier == SubscriptionCategory.other.rawValue }) {
            return other
        }
        if let first = categories.first {
            return first
        }
        return AppCategory(
            identifier: SubscriptionCategory.other.rawValue,
            name: SubscriptionCategory.other.title,
            iconName: SubscriptionCategory.other.icon,
            colorHex: SubscriptionCategory.other.hex,
            isBuiltIn: true,
            sortOrder: 99
        )
    }

    static func seedBuiltIns(in context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<AppCategory>())) ?? []
        let existingIDs = Set(existing.map(\.identifier))

        for (index, preset) in SubscriptionCategory.allCases.enumerated() {
            guard !existingIDs.contains(preset.rawValue) else { continue }
            context.insert(
                AppCategory(
                    identifier: preset.rawValue,
                    name: preset.title,
                    iconName: preset.icon,
                    colorHex: preset.hex,
                    isBuiltIn: true,
                    sortOrder: index
                )
            )
        }

        try? context.save()
    }
}

enum CategoryColorPreset: String, CaseIterable, Identifiable {
    case red, orange, amber, green, teal, blue, indigo, purple, pink, gray, brown, mint

    var id: String { rawValue }

    var hex: String {
        switch self {
        case .red: "E84C3D"
        case .orange: "F2732B"
        case .amber: "F29B12"
        case .green: "2EB878"
        case .teal: "26AD9F"
        case .blue: "3399DB"
        case .indigo: "5E5CE6"
        case .purple: "9B59B6"
        case .pink: "E84393"
        case .gray: "78858F"
        case .brown: "A0522D"
        case .mint: "1ABC9C"
        }
    }

    var color: Color { Color(hex: hex) }
}

enum CategoryIconLibrary {
    static let all: [String] = [
        "tag.fill",
        "star.fill",
        "heart.fill",
        "house.fill",
        "car.fill",
        "airplane",
        "gift.fill",
        "creditcard.fill",
        "phone.fill",
        "leaf.fill",
        "bolt.fill",
        "flame.fill",
        "drop.fill",
        "pawprint.fill",
        "hammer.fill",
        "stethoscope",
        "pills.fill",
        "fork.knife",
        "cup.and.saucer.fill",
        "tshirt.fill",
        "bag.fill",
        "cart.fill",
        "building.2.fill",
        "globe",
        "wifi",
        "externaldrive.fill",
        "play.tv.fill",
        "music.note",
        "gamecontroller.fill",
        "book.fill",
        "newspaper.fill",
        "chart.line.uptrend.xyaxis",
        "banknote.fill",
        "laptopcomputer",
        "cloud.fill",
        "figure.run",
        "paintbrush.fill",
        "camera.fill",
        "headphones",
        "tv.fill",
        "ticket.fill",
        "banknote.fill",
    ]
}

private struct AppCategoriesKey: EnvironmentKey {
    static let defaultValue: [AppCategory] = []
}

extension EnvironmentValues {
    var appCategories: [AppCategory] {
        get { self[AppCategoriesKey.self] }
        set { self[AppCategoriesKey.self] = newValue }
    }
}

extension Subscription {
    func resolvedCategory(in categories: [AppCategory]) -> AppCategory {
        AppCategory.resolve(categoryRaw, in: categories)
    }
}
