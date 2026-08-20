import Foundation
import SwiftData
import SwiftUI

@Model
final class AppPaymentMethod {
    var identifier: String = UUID().uuidString
    var name: String = ""
    var iconName: String = "creditcard.fill"
    var colorHex: String = "5E5CE6"
    var isBuiltIn: Bool = false
    var sortOrder: Int = 0
    var createdAt: Date = Date()

    var color: Color {
        Color(hex: colorHex)
    }

    var localizedName: String {
        if isBuiltIn, let preset = PaymentMethod(rawValue: identifier) {
            return preset.title
        }
        return name
    }

    var builtInMethod: PaymentMethod? {
        isBuiltIn ? PaymentMethod(rawValue: identifier) : nil
    }

    init(
        identifier: String = UUID().uuidString,
        name: String,
        iconName: String,
        colorHex: String = "5E5CE6",
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

    static func resolve(_ identifier: String, in methods: [AppPaymentMethod]) -> AppPaymentMethod {
        let id = PaymentMethod.normalizedID(identifier)
        if let match = methods.first(where: { $0.identifier == id }) {
            return match
        }
        if let other = methods.first(where: { $0.identifier == PaymentMethod.other.rawValue }) {
            return other
        }
        if let first = methods.first {
            return first
        }
        return AppPaymentMethod(
            identifier: PaymentMethod.other.rawValue,
            name: PaymentMethod.other.title,
            iconName: "ellipsis.circle.fill",
            isBuiltIn: true,
            sortOrder: 99
        )
    }

    static func seedBuiltIns(in context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<AppPaymentMethod>())) ?? []
        let existingIDs = Set(existing.map(\.identifier))
        let startOrder = (existing.map(\.sortOrder).max() ?? -1) + 1

        for (offset, preset) in PaymentMethod.allCases.enumerated() where !existingIDs.contains(preset.rawValue) {
            context.insert(
                AppPaymentMethod(
                    identifier: preset.rawValue,
                    name: preset.title,
                    iconName: preset.rawValue,
                    isBuiltIn: true,
                    sortOrder: startOrder + offset
                )
            )
        }

        try? context.save()
    }
}

enum PaymentIconLibrary {
    static let all: [String] = [
        "creditcard.fill",
        "creditcard",
        "wallet.pass.fill",
        "banknote.fill",
        "building.columns.fill",
        "p.circle.fill",
        "ellipsis.circle.fill",
        "globe",
        "iphone",
        "qrcode",
        "person.crop.rectangle.fill",
        "lock.fill",
    ]
}

private struct AppPaymentMethodsKey: EnvironmentKey {
    static let defaultValue: [AppPaymentMethod] = []
}

extension EnvironmentValues {
    var appPaymentMethods: [AppPaymentMethod] {
        get { self[AppPaymentMethodsKey.self] }
        set { self[AppPaymentMethodsKey.self] = newValue }
    }
}

extension Subscription {
    func resolvedPaymentMethod(in methods: [AppPaymentMethod]) -> AppPaymentMethod {
        AppPaymentMethod.resolve(paymentMethodRaw, in: methods)
    }
}
