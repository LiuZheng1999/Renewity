import SwiftData
import SwiftUI

struct PaymentMethodPickerView: View {
    @Binding var selection: String
    @Query(sort: \AppPaymentMethod.sortOrder) private var methods: [AppPaymentMethod]
    @Query private var subscriptions: [Subscription]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var editMode: EditMode = .inactive
    @State private var showingAdd = false

    var body: some View {
        List {
            ForEach(methods) { method in
                Group {
                    if isEditing {
                        methodRow(method)
                    } else {
                        Button {
                            selection = method.identifier
                            dismiss()
                        } label: {
                            methodRow(method)
                        }
                        .foregroundStyle(.primary)
                    }
                }
                .deleteDisabled(method.isBuiltIn)
            }
            .onMove(perform: move)
            .onDelete(perform: delete)
        }
        .environment(\.editMode, $editMode)
        .navigationTitle("支付方式")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("新建", systemImage: "plus") {
                    showingAdd = true
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(editMode.isEditing ? "完成" : "编辑") {
                    withAnimation {
                        editMode = editMode.isEditing ? .inactive : .active
                    }
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            PaymentMethodFormView { created in
                selection = created.identifier
            }
        }
    }

    private var isEditing: Bool {
        editMode.isEditing
    }

    private func methodRow(_ method: AppPaymentMethod) -> some View {
        HStack(spacing: 12) {
            PaymentMethodGlyph(method: method)
            Text(method.localizedName)
            Spacer()
            if !isEditing, PaymentMethod.normalizedID(selection) == method.identifier {
                Image(systemName: "checkmark")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentColor)
            }
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        var ordered = methods
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, item) in ordered.enumerated() {
            item.sortOrder = index
        }
    }

    private func delete(at offsets: IndexSet) {
        let otherID = PaymentMethod.other.rawValue
        for index in offsets {
            let method = methods[index]
            guard !method.isBuiltIn else { continue }
            for subscription in subscriptions where subscription.paymentMethodRaw == method.identifier {
                subscription.paymentMethodRaw = otherID
            }
            if selection == method.identifier {
                selection = otherID
            }
            modelContext.delete(method)
        }
    }
}

struct PaymentMethodFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \AppPaymentMethod.sortOrder) private var methods: [AppPaymentMethod]

    var onSave: ((AppPaymentMethod) -> Void)?

    @State private var name = ""
    @State private var iconName = "creditcard.fill"
    @State private var colorHex = CategoryColorPreset.indigo.hex

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("预览") {
                    HStack(spacing: 12) {
                        PaymentMethodGlyph(
                            identifier: "",
                            iconName: iconName,
                            colorHex: colorHex,
                            isBuiltIn: false
                        )
                        Text(name.isEmpty ? String(localized: "新支付方式") : name)
                            .font(.headline)
                    }
                }

                Section("名称") {
                    TextField("例如：公司卡、家庭账户", text: $name)
                }

                Section("颜色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(CategoryColorPreset.allCases) { preset in
                            Button {
                                colorHex = preset.hex
                            } label: {
                                Circle()
                                    .fill(preset.color.gradient)
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        if colorHex.caseInsensitiveCompare(preset.hex) == .orderedSame {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("图标") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(PaymentIconLibrary.all, id: \.self) { icon in
                            Button {
                                iconName = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.body)
                                    .frame(width: 36, height: 36)
                                    .foregroundStyle(iconName == icon ? Color.white : Color.primary)
                                    .background(
                                        iconName == icon ? Color(hex: colorHex) : Color.secondary.opacity(0.12),
                                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("新建支付方式")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let nextOrder = (methods.map(\.sortOrder).max() ?? 0) + 1
        let item = AppPaymentMethod(
            name: trimmed,
            iconName: iconName,
            colorHex: colorHex,
            isBuiltIn: false,
            sortOrder: nextOrder
        )
        modelContext.insert(item)
        onSave?(item)
        dismiss()
    }
}

struct PaymentMethodGlyph: View {
    var identifier: String
    var iconName: String
    var colorHex: String
    var isBuiltIn: Bool
    var width: CGFloat = 40

    init(method: AppPaymentMethod, width: CGFloat = 40) {
        identifier = method.identifier
        iconName = method.iconName
        colorHex = method.colorHex
        isBuiltIn = method.isBuiltIn
        self.width = width
    }

    init(
        identifier: String,
        iconName: String,
        colorHex: String,
        isBuiltIn: Bool,
        width: CGFloat = 40
    ) {
        self.identifier = identifier
        self.iconName = iconName
        self.colorHex = colorHex
        self.isBuiltIn = isBuiltIn
        self.width = width
    }

    private var height: CGFloat { width * 0.64 }
    private var cornerRadius: CGFloat { width * 0.18 }

    var body: some View {
        Group {
            if let preset = PaymentMethod(rawValue: identifier),
               let artworkName = preset.artworkName,
               BrandArtwork.exists(artworkName) {
                Image(artworkName)
                    .resizable()
                    .scaledToFill()
            } else if isBuiltIn, let preset = PaymentMethod(rawValue: identifier) {
                brandMark(preset)
            } else {
                Image(systemName: iconName)
                    .font(.system(size: width * 0.38, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(hex: colorHex).gradient)
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(.black.opacity(0.08), lineWidth: 0.5)
        }
    }

    @ViewBuilder
    private func brandMark(_ method: PaymentMethod) -> some View {
        switch method {
        case .applePay:
            HStack(spacing: width * 0.06) {
                Image(systemName: "applelogo")
                    .font(.system(size: width * 0.28, weight: .semibold))
                Text(verbatim: "Pay")
                    .font(.system(size: width * 0.28, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)

        case .googlePay:
            HStack(spacing: width * 0.05) {
                Text(verbatim: "G")
                    .font(.system(size: width * 0.34, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "4285F4"))
                Text(verbatim: "Pay")
                    .font(.system(size: width * 0.26, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: "5F6368"))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)

        case .paypal:
            HStack(spacing: -width * 0.08) {
                Text(verbatim: "P")
                    .font(.system(size: width * 0.42, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(hex: "003087"))
                Text(verbatim: "P")
                    .font(.system(size: width * 0.42, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(hex: "009CDE"))
                    .offset(x: -width * 0.02, y: width * 0.04)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)

        case .visa:
            Text(verbatim: "VISA")
                .font(.system(size: width * 0.28, weight: .heavy, design: .serif))
                .italic()
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "1A1F71"))

        case .mastercard:
            ZStack {
                Circle()
                    .fill(Color(hex: "EB001B"))
                    .frame(width: width * 0.38, height: width * 0.38)
                    .offset(x: -width * 0.11)
                Circle()
                    .fill(Color(hex: "F79E1B"))
                    .frame(width: width * 0.38, height: width * 0.38)
                    .offset(x: width * 0.11)
                Circle()
                    .fill(Color(hex: "FF5F00").opacity(0.92))
                    .frame(width: width * 0.22, height: width * 0.38)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "1A1A1A"))

        case .amex:
            Text(verbatim: "AMEX")
                .font(.system(size: width * 0.22, weight: .heavy, design: .rounded))
                .tracking(width * 0.01)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "006FCF"))

        case .creditCard:
            genericCard(Color(hex: "2C3E6B"), symbol: "creditcard.fill")

        case .debitCard:
            genericCard(Color(hex: "1F7A4D"), symbol: "creditcard")

        case .bankTransfer:
            genericCard(Color(hex: "3458A8"), symbol: "building.columns.fill")

        case .other:
            genericCard(Color(hex: "6B7280"), symbol: "ellipsis")
        }
    }

    private func genericCard(_ color: Color, symbol: String) -> some View {
        ZStack(alignment: .leading) {
            Rectangle().fill(color.gradient)
            VStack(alignment: .leading, spacing: width * 0.08) {
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(Color.yellow.opacity(0.85))
                    .frame(width: width * 0.18, height: width * 0.13)
                Image(systemName: symbol)
                    .font(.system(size: width * 0.2, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
            }
            .padding(.leading, width * 0.1)
        }
    }
}

#Preview {
    NavigationStack {
        PaymentMethodPickerView(selection: .constant(PaymentMethod.applePay.rawValue))
    }
    .modelContainer(PreviewContainer.sample)
}
