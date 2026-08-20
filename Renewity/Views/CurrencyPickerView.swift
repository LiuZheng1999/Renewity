import SwiftUI

struct CurrencyPickerView: View {
    @Binding var currencyCode: String
    var onSelect: ((String) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var common: [(code: String, name: String)] {
        AppConfig.supportedCurrencies.filter { matches($0.code, name: $0.name) }
    }

    private var allCodes: [String] {
        let commonCodes = Set(AppConfig.supportedCurrencies.map(\.code))
        return Locale.Currency.isoCurrencies
            .map(\.identifier)
            .filter { !commonCodes.contains($0) }
            .filter { AppConfig.isSelectableCurrency($0) }
            .filter { matches($0, name: Formatters.currencyFullName(for: $0)) }
            .sorted()
    }

    var body: some View {
        NavigationStack {
            List {
                Section("常用货币") {
                    ForEach(common, id: \.code) { item in
                        currencyRow(code: item.code, name: item.name)
                    }
                }

                Section("所有货币") {
                    ForEach(allCodes, id: \.self) { code in
                        currencyRow(code: code, name: Formatters.currencyFullName(for: code))
                    }
                }
            }
            .navigationTitle("选择货币")
            .toolbarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "搜索货币")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }

    private func currencyRow(code: String, name: String) -> some View {
        Button {
            if let onSelect {
                onSelect(code)
            } else {
                currencyCode = code
            }
            dismiss()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Formatters.currencyPickerTitle(for: code))
                        .foregroundStyle(.primary)
                    Text(name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if currencyCode == code {
                    Image(systemName: "checkmark")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }

    private func matches(_ code: String, name: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        let symbol = Formatters.currencySymbol(for: code)
        return code.localizedCaseInsensitiveContains(trimmed)
            || name.localizedCaseInsensitiveContains(trimmed)
            || symbol.localizedCaseInsensitiveContains(trimmed)
    }
}
