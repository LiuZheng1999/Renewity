import SwiftData
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct SubscriptionFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let subscription: Subscription?

    @State private var name: String
    @State private var priceText: String
    @State private var isPriceFieldFocused = false
    @State private var billingCycle: BillingCycle
    @State private var categoryID: String
    @State private var billingDate: Date
    @State private var billingDateKind: BillingDateKind = .next
    @State private var oneTimeDateKind: OneTimeDateKind = .charge
    @State private var notes: String
    @State private var managementURLText: String
    @State private var iconName: String
    @State private var paymentMethodID: String
    @State private var customCycleValue: Int
    @State private var customCycleUnit: CustomCycleUnit
    @State private var accentColorHex: String
    @State private var customIconID: String
    @State private var reminderDrafts: [ReminderDraft]
    @State private var hasTrial: Bool
    @State private var trialEndDate: Date
    @State private var trialReminderDrafts: [ReminderDraft]
    @State private var isActive: Bool
    @State private var doesRenew: Bool
    @State private var isPickingBrand: Bool
    @State private var showingCategoryForm = false
    @State private var showingPaywall = false
    @State private var showingCurrencyPicker = false
    @State private var billingCurrencyCode: String
    @State private var pendingBillingCurrencyCode: String?

    @Query(sort: \AppCategory.sortOrder) private var categories: [AppCategory]
    @Query(sort: \AppPaymentMethod.sortOrder) private var paymentMethods: [AppPaymentMethod]
    @Environment(ProStore.self) private var proStore

    init(subscription: Subscription? = nil) {
        self.subscription = subscription
        _name = State(initialValue: subscription?.name ?? "")
        _priceText = State(initialValue: subscription.map { Self.priceInputText(from: $0.price) } ?? "")
        _billingCycle = State(initialValue: subscription?.billingCycle ?? .monthly)
        _categoryID = State(initialValue: subscription?.categoryRaw ?? SubscriptionCategory.other.rawValue)
        if let subscription, let trialEnd = subscription.trialEndDate, subscription.isInTrial {
            _billingDate = State(initialValue: trialEnd)
            _billingDateKind = State(initialValue: .next)
        } else {
            _billingDate = State(initialValue: subscription?.upcomingBillingDate ?? .now)
            if subscription == nil {
                let storedKind = UserDefaults.standard.string(forKey: AppConfig.lastCreatedBillingDateKindKey) ?? ""
                _billingDateKind = State(initialValue: BillingDateKind(rawValue: storedKind) ?? .next)
            }
        }
        _notes = State(initialValue: subscription?.notes ?? "")
        _managementURLText = State(initialValue: subscription?.managementURL ?? "")
        _iconName = State(initialValue: subscription?.iconName ?? "")
        let fallbackPayment = UserDefaults.standard.string(forKey: AppConfig.lastCreatedPaymentMethodKey)
            ?? PaymentMethod.applePay.rawValue
        _paymentMethodID = State(initialValue: PaymentMethod.normalizedID(subscription?.paymentMethodRaw ?? fallbackPayment))
        _customCycleValue = State(initialValue: max(1, subscription?.customCycleValue ?? 1))
        _customCycleUnit = State(initialValue: subscription?.customCycleUnit ?? .month)
        _accentColorHex = State(initialValue: subscription?.accentColorHex ?? "")
        _customIconID = State(initialValue: {
            if let icon = subscription?.iconName, icon.hasPrefix(ServiceIconStore.prefix) {
                return String(icon.dropFirst(ServiceIconStore.prefix.count))
            }
            return "custom.\(UUID().uuidString)"
        }())
        _reminderDrafts = State(initialValue: (subscription?.reminderOffsets ?? []).map { ReminderDraft(days: $0) })
        _hasTrial = State(initialValue: subscription?.isInTrial ?? false)
        _trialEndDate = State(initialValue: subscription?.trialEndDate ?? Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now)
        _trialReminderDrafts = State(initialValue: {
            if let subscription, subscription.isInTrial {
                return subscription.trialReminderOffsets.map { ReminderDraft(days: $0) }
            }
            return [ReminderDraft(days: 1)]
        }())
        _isActive = State(initialValue: subscription?.isActive ?? true)
        _doesRenew = State(initialValue: subscription?.doesRenew ?? true)
        _isPickingBrand = State(initialValue: subscription == nil)
        let stored = subscription?.resolvedCurrencyCode
            ?? UserDefaults.standard.string(forKey: "currencyCode")
            ?? "CNY"
        _billingCurrencyCode = State(initialValue: stored)
    }

    private var isEditing: Bool {
        subscription != nil
    }

    private var parsedPrice: Decimal? {
        PriceInput.parse(priceText)
    }

    private static func priceInputText(from value: Decimal) -> String {
        NSDecimalNumber(decimal: PriceInput.round(value)).stringValue
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && PriceInput.isSavable(parsedPrice)
    }

    var body: some View {
        NavigationStack {
            Group {
                if isPickingBrand {
                    BrandPickerView(onSelect: applyTemplate, onCustom: { suggestedName in
                        applyCustomName(suggestedName)
                    })
                    .navigationTitle("选择服务")
                } else {
                    formContent
                }
            }
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                if !isPickingBrand {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("保存") {
                            save()
                        }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingCategoryForm) {
                CategoryFormView { created in
                    categoryID = created.identifier
                }
            }
            .fullScreenCover(isPresented: $showingPaywall, onDismiss: applyPendingBillingCurrencyIfPro) {
                PaywallView()
            }
            .sheet(isPresented: $showingCurrencyPicker, onDismiss: presentPaywallIfBillingCurrencyLocked) {
                CurrencyPickerView(currencyCode: $billingCurrencyCode, onSelect: handleBillingCurrencySelect)
            }
        }
    }

    private var selectedCategory: AppCategory {
        AppCategory.resolve(categoryID, in: categories)
    }

    private var selectedPaymentMethod: AppPaymentMethod {
        AppPaymentMethod.resolve(paymentMethodID, in: paymentMethods)
    }

    private var serviceRowBackground: Color {
        if accentColorHex.isEmpty {
            return Color.groupedSecondary
        }
        return Color(hex: accentColorHex).opacity(0.22)
    }

    private var amountRow: some View {
        HStack(spacing: 10) {
            Text("金额")
            TrailingDecimalTextField(
                text: $priceText,
                placeholder: String(localized: "输入金额"),
                isFocused: $isPriceFieldFocused
            )
            .frame(maxWidth: .infinity, minHeight: 40)
            .contentShape(Rectangle())
            .onTapGesture {
                isPriceFieldFocused = true
            }
            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(width: 1, height: 22)
            Button {
                isPriceFieldFocused = false
                showingCurrencyPicker = true
            } label: {
                HStack(spacing: 4) {
                    Text(Formatters.currencyPickerTitle(for: billingCurrencyCode))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .frame(minHeight: 40)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
            .accessibilityLabel("付款货币")
        }
        .frame(minHeight: 40)
    }

    private var formContent: some View {
        Form {
            Section() {
                NavigationLink {
                    ServiceAppearanceView(
                        name: $name,
                        iconName: $iconName,
                        accentColorHex: $accentColorHex,
                        fallbackColor: selectedCategory.color,
                        customIconID: customIconID
                    )
                } label: {
                    HStack(spacing: 12) {
                        SubscriptionIconView(
                            iconName: iconName.isEmpty ? selectedCategory.iconName : iconName,
                            color: selectedCategory.color,
                            size: 44
                        )
                        Text(name.isEmpty ? String(localized: "未命名订阅") : name)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                }
                .listRowBackground(serviceRowBackground)
            }

            Section() {
                Picker("分类", selection: $categoryID) {
                    ForEach(categories, id: \.identifier) { item in
                        Label(item.localizedName, systemImage: item.iconName).tag(item.identifier)
                    }
                    Label("新建分类", systemImage: proStore.isPro ? "plus" : "lock.fill")
                        .tag(Self.newCategoryTag)
                }
                .onChange(of: categoryID) { oldValue, newValue in
                    handleCategoryChange(from: oldValue, to: newValue)
                }
                
                NavigationLink {
                    PaymentMethodPickerView(selection: $paymentMethodID)
                } label: {
                    HStack {
                        Text("支付方式")
                        Spacer()
                        PaymentMethodGlyph(method: selectedPaymentMethod, width: 36)
                        Text(selectedPaymentMethod.localizedName)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section() {
                amountRow
                Picker("计费方式", selection: $doesRenew) {
                    Text("自动续订").tag(true)
                    Text("一次性").tag(false)
                }
                .pickerStyle(.menu)
                .onChange(of: doesRenew) { _, renews in
                    if !renews {
                        billingDateKind = .next
                        oneTimeDateKind = .charge
                        isActive = true
                    }
                }
                if doesRenew {
                    Picker("订阅周期", selection: $billingCycle) {
                        ForEach(BillingCycle.allCases) { cycle in
                            Text(cycle.title).tag(cycle)
                        }
                    }
                    .pickerStyle(.menu)
                    if billingCycle == .custom {
                        Stepper(value: $customCycleValue, in: 1...365) {
                            Text("每隔 \(customCycleValue) \(customCycleUnit.title)")
                        }
                        Picker("单位", selection: $customCycleUnit) {
                            ForEach(CustomCycleUnit.allCases) { unit in
                                Text(unit.title).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }

            Section {
                billingDateRow
                    .onChange(of: billingDate) { _, newValue in
                        if hasTrial {
                            billingDateKind = .next
                            trialEndDate = newValue
                        }
                    }
                    .onChange(of: billingDateKind) { oldKind, newKind in
                        convertBillingDate(from: oldKind, to: newKind)
                    }
                Toggle("试用期", isOn: $hasTrial)
                    .onChange(of: hasTrial) { _, enabled in
                        guard enabled else { return }
                        if trialReminderDrafts.isEmpty {
                            trialReminderDrafts = [ReminderDraft(days: 1)]
                        }
                        billingDateKind = .next
                        trialEndDate = billingDate
                    }
                if hasTrial {
                    HStack {
                        ForEach([7, 14, 30], id: \.self) { days in
                            Button(trialPresetTitle(days)) {
                                applyTrialPreset(days)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .fontWeight(isTrialPreset(days) ? .semibold : .regular)
                        }
                    }
                    Toggle("试用提醒", isOn: trialRemindersEnabledBinding)
                    if !trialReminderDrafts.isEmpty {
                        ForEach($trialReminderDrafts) { $draft in
                            ReminderEditorRow(
                                draft: $draft,
                                canDelete: trialReminderDrafts.count > 1,
                                onDelete: {
                                    trialReminderDrafts.removeAll { $0.id == draft.id }
                                }
                            )
                        }
                        if trialReminderDrafts.count < ReminderLead.maxCount {
                            Button {
                                addReminder($trialReminderDrafts)
                            } label: {
                                Label(
                                    "添加更多提醒",
                                    systemImage: trialReminderDrafts.count >= ReminderLead.freeCount && !proStore.isPro
                                        ? "lock.fill"
                                        : "plus"
                                )
                            }
                        }
                    }
                }
            } header: {
                if doesRenew {
                    Text("续订")
                }
            } footer: {
                if doesRenew, hasTrial {
                    Text("试用持续到下次付款日，当天开始按上面的费用付款。")
                }
            }

            Section() {
                Toggle(doesRenew ? "续订提醒" : "付款提醒", isOn: remindersEnabledBinding)
                if !reminderDrafts.isEmpty {
                    ForEach($reminderDrafts) { $draft in
                        ReminderEditorRow(
                            draft: $draft,
                            canDelete: reminderDrafts.count > 1,
                            onDelete: {
                                reminderDrafts.removeAll { $0.id == draft.id }
                            }
                        )
                    }
                    if reminderDrafts.count < ReminderLead.maxCount {
                        Button {
                            addReminder($reminderDrafts)
                        } label: {
                            Label(
                                "添加更多提醒",
                                systemImage: reminderDrafts.count >= ReminderLead.freeCount && !proStore.isPro
                                    ? "lock.fill"
                                    : "plus"
                            )
                        }
                    }
                }
            }

            Section {
                TextField("https://", text: $managementURLText)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("管理页面")
            } footer: {
                Text("填写该服务的账号或订阅管理链接。点详情页的「管理订阅」会打开这个地址。")
            }

            Section("备注") {
                TextField("可选", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .tint(.primary)
        .navigationTitle(isEditing ? String(localized: "编辑订阅") : String(localized: "添加订阅"))
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") {
                    dismissKeyboard()
                }
            }
        }
    }

    private static let newCategoryTag = "__new_category__"

    private func dismissKeyboard() {
        isPriceFieldFocused = false
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }

    private var billingDateRow: some View {
        HStack {
            billingDateTitle
            Spacer(minLength: 8)
            DatePicker(
                "",
                selection: $billingDate,
                displayedComponents: .date
            )
            .labelsHidden()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(billingDateTitleText)
    }

    private var billingDateTitleText: String {
        if !doesRenew {
            return oneTimeDateKind.title
        }
        return hasTrial ? String(localized: "付款日期") : billingDateKind.title
    }

    @ViewBuilder
    private var billingDateTitle: some View {
        if hasTrial, doesRenew {
            Text("付款日期")
        } else if !doesRenew {
            Menu {
                Picker("日期类型", selection: $oneTimeDateKind) {
                    ForEach(OneTimeDateKind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
            } label: {
                dateKindMenuLabel(oneTimeDateKind.title)
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .accessibilityLabel(oneTimeDateKind.title)
            .accessibilityHint("选择付款日期或到期日")
        } else {
            Menu {
                Picker("付款日期", selection: $billingDateKind) {
                    ForEach(BillingDateKind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
            } label: {
                dateKindMenuLabel(billingDateKind.title)
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .accessibilityLabel(billingDateKind.title)
            .accessibilityHint("选择下次付款或上次付款")
        }
    }

    private func dateKindMenuLabel(_ title: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.primary)
    }

    private func convertBillingDate(from oldKind: BillingDateKind, to newKind: BillingDateKind) {
        switch (oldKind, newKind) {
        case (.next, .last):
            billingDate = billingCycle.previousDate(
                before: billingDate,
                customValue: customCycleValue,
                customUnit: customCycleUnit
            )
        case (.last, .next):
            billingDate = billingCycle.nextBillingDate(
                afterLastCharge: billingDate,
                customValue: customCycleValue,
                customUnit: customCycleUnit
            )
        default:
            break
        }
    }

    private var remindersEnabledBinding: Binding<Bool> {
        Binding(
            get: { !reminderDrafts.isEmpty },
            set: { on in
                if on {
                    if reminderDrafts.isEmpty {
                        reminderDrafts = [ReminderDraft(days: 1)]
                    }
                } else {
                    reminderDrafts = []
                }
            }
        )
    }

    private var trialRemindersEnabledBinding: Binding<Bool> {
        Binding(
            get: { !trialReminderDrafts.isEmpty },
            set: { on in
                if on {
                    if trialReminderDrafts.isEmpty {
                        trialReminderDrafts = [ReminderDraft(days: 1)]
                    }
                } else {
                    trialReminderDrafts = []
                }
            }
        )
    }

    private func addReminder(_ drafts: Binding<[ReminderDraft]>) {
        if drafts.wrappedValue.count >= ReminderLead.freeCount && !proStore.isPro {
            showingPaywall = true
            return
        }
        guard drafts.wrappedValue.count < ReminderLead.maxCount else { return }
        let next = ReminderLead.nextUnused(from: drafts.wrappedValue.map(\.days))
        drafts.wrappedValue.append(ReminderDraft(days: next))
    }

    private func trialPresetTitle(_ days: Int) -> String {
        String(localized: "\(days) 天")
    }

    private func isTrialPreset(_ days: Int) -> Bool {
        let calendar = Calendar.current
        let expected = calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: Date())) ?? Date()
        return calendar.isDate(billingDate, inSameDayAs: expected)
    }

    private func applyTrialPreset(_ days: Int) {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: Date())) ?? Date()
        billingDateKind = .next
        billingDate = date
        trialEndDate = date
    }

    private func handleBillingCurrencySelect(_ code: String) {
        guard code != billingCurrencyCode else { return }
        if proStore.isPro {
            billingCurrencyCode = code
        } else {
            pendingBillingCurrencyCode = code
        }
    }

    private func presentPaywallIfBillingCurrencyLocked() {
        guard pendingBillingCurrencyCode != nil, !proStore.isPro else { return }
        DispatchQueue.main.async {
            showingPaywall = true
        }
    }

    private func applyPendingBillingCurrencyIfPro() {
        guard let pendingBillingCurrencyCode else { return }
        if proStore.isPro {
            billingCurrencyCode = pendingBillingCurrencyCode
        }
        self.pendingBillingCurrencyCode = nil
    }

    private func handleCategoryChange(from oldValue: String, to newValue: String) {
        guard newValue == Self.newCategoryTag else { return }
        let fallback = categories.first?.identifier ?? SubscriptionCategory.other.rawValue
        categoryID = (oldValue == Self.newCategoryTag || oldValue.isEmpty) ? fallback : oldValue
        if proStore.isPro {
            showingCategoryForm = true
        } else {
            showingPaywall = true
        }
    }

    private func applyTemplate(_ template: SubscriptionTemplate) {
        name = template.name
        if !isEditing {
            priceText = ""
        }
        billingCycle = template.cycle
        categoryID = template.category.rawValue
        iconName = template.isCustomDraft ? "" : template.iconName
        if managementURLText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let suggested = SubscriptionManageLinks.suggested(iconName: iconName, name: template.name) {
            managementURLText = suggested.absoluteString
        }
        isPickingBrand = false
    }

    private func applyCustomName(_ suggestedName: String) {
        let trimmed = suggestedName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            name = trimmed
        }
        isPickingBrand = false
    }

    private func save() {
        guard let parsed = parsedPrice else { return }
        let price = PriceInput.round(parsed)
        guard PriceInput.isSavable(price) else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedIcon = iconName.isEmpty ? selectedCategory.iconName : iconName
        let item: Subscription

        if let subscription {
            subscription.name = trimmedName
            subscription.price = price
            subscription.applyBillingCurrency(billingCurrencyCode)
            subscription.billingCycle = billingCycle
            subscription.categoryRaw = categoryID
            subscription.notes = notes
            subscription.managementURL = managementURLText.trimmingCharacters(in: .whitespacesAndNewlines)
            subscription.iconName = resolvedIcon
            subscription.paymentMethodRaw = paymentMethodID
            subscription.customCycleValue = max(1, customCycleValue)
            subscription.customCycleUnit = customCycleUnit
            subscription.accentColorHex = accentColorHex
            subscription.doesRenew = doesRenew
            subscription.applyReminderOffsets(reminderDrafts.map(\.days))
            if hasTrial {
                let chargeDate = Calendar.current.startOfDay(for: billingDate)
                subscription.nextBillingDate = chargeDate
                subscription.trialEndDate = chargeDate
                subscription.applyTrialReminderOffsets(trialReminderDrafts.map(\.days))
            } else {
                subscription.nextBillingDate = resolvedNextBillingDate
                subscription.clearTrial()
            }
            subscription.isActive = isActive
            item = subscription
        } else {
            let chargeDate = Calendar.current.startOfDay(for: billingDate)
            item = Subscription(
                name: trimmedName,
                price: price,
                currencyCode: billingCurrencyCode,
                billingCycle: billingCycle,
                category: SubscriptionCategory(rawValue: categoryID) ?? .other,
                nextBillingDate: hasTrial ? chargeDate : resolvedNextBillingDate,
                notes: notes,
                isActive: isActive,
                iconName: resolvedIcon,
                paymentMethod: PaymentMethod(rawValue: paymentMethodID) ?? .other,
                customCycleValue: customCycleValue,
                customCycleUnit: customCycleUnit,
                accentColorHex: accentColorHex,
                reminderOffsets: reminderDrafts.map(\.days),
                trialEndDate: hasTrial ? chargeDate : nil,
                trialReminderOffsets: hasTrial ? trialReminderDrafts.map(\.days) : [],
                managementURL: managementURLText.trimmingCharacters(in: .whitespacesAndNewlines),
                doesRenew: doesRenew
            )
            item.categoryRaw = categoryID
            item.paymentMethodRaw = paymentMethodID
            modelContext.insert(item)
            UserDefaults.standard.set(paymentMethodID, forKey: AppConfig.lastCreatedPaymentMethodKey)
            if doesRenew {
                UserDefaults.standard.set(billingDateKind.rawValue, forKey: AppConfig.lastCreatedBillingDateKindKey)
            }
        }

        Task {
            if !item.reminderOffsets.isEmpty || !item.trialReminderOffsets.isEmpty {
                await ReminderService.requestAuthorizationIfNeeded()
            }
            ReminderService.reschedule(for: item)
        }

        dismiss()
    }

    private var resolvedNextBillingDate: Date {
        if !doesRenew { return billingDate }
        switch billingDateKind {
        case .next:
            return billingDate
        case .last:
            return billingCycle.nextBillingDate(
                afterLastCharge: billingDate,
                customValue: customCycleValue,
                customUnit: customCycleUnit
            )
        }
    }
}

private struct ReminderDraft: Identifiable, Equatable {
    let id = UUID()
    var days: Int
}

private struct ReminderEditorRow: View {
    @Binding var draft: ReminderDraft
    var canDelete: Bool
    var onDelete: () -> Void

    private var leadBinding: Binding<ReminderLead> {
        Binding(
            get: { ReminderLead.matching(draft.days) },
            set: { lead in
                if let days = lead.presetDays {
                    draft.days = days
                } else if ReminderLead.matching(draft.days) != .custom {
                    draft.days = 10
                }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Picker("提醒时间", selection: leadBinding) {
                    ForEach(ReminderLead.presets) { lead in
                        Text(lead.title).tag(lead)
                    }
                }
                .pickerStyle(.menu)
                if canDelete {
                    Button(action: onDelete) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("删除提醒")
                }
            }
            if ReminderLead.matching(draft.days) == .custom {
                Stepper(value: $draft.days, in: 1...90) {
                    Text(ReminderLead.title(for: draft.days))
                }
            }
        }
    }
}

private enum PriceInput {
    static let maxValue = Decimal(string: "999999999.99")!
    static let maxFractionDigits = 2
    static let maxIntegerDigits = 9

    static func parse(_ raw: String) -> Decimal? {
        let text = raw
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, text != "." else { return nil }
        return Decimal(string: text)
    }

    static func round(_ value: Decimal) -> Decimal {
        var rounded = Decimal()
        var source = value
        NSDecimalRound(&rounded, &source, maxFractionDigits, .plain)
        return rounded
    }

    static func isSavable(_ value: Decimal?) -> Bool {
        guard let value else { return false }
        return value > 0 && value <= maxValue
    }

    static func isAllowed(_ raw: String) -> Bool {
        if raw.isEmpty { return true }
        var sawSeparator = false
        var integerDigits = 0
        var fractionDigits = 0
        for character in raw {
            if character >= "0" && character <= "9" {
                if sawSeparator {
                    fractionDigits += 1
                    if fractionDigits > maxFractionDigits { return false }
                } else {
                    integerDigits += 1
                    if integerDigits > maxIntegerDigits { return false }
                }
            } else if character == "." || character == "," {
                guard !sawSeparator else { return false }
                sawSeparator = true
            } else {
                return false
            }
        }
        if let value = parse(raw), value > maxValue { return false }
        return true
    }
}

#if canImport(UIKit)
private struct TrailingDecimalTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    @Binding var isFocused: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, isFocused: $isFocused)
    }

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.placeholder = placeholder
        field.keyboardType = .decimalPad
        field.textAlignment = .right
        field.adjustsFontForContentSizeCategory = true
        let size = UIFont.preferredFont(forTextStyle: .body).pointSize
        field.font = UIFont.monospacedDigitSystemFont(ofSize: size, weight: .regular)
        field.delegate = context.coordinator
        field.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .editingChanged)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        field.inputAccessoryView = context.coordinator.makeAccessoryView()
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        context.coordinator.text = $text
        context.coordinator.isFocused = $isFocused
        if field.text != text {
            field.text = text
        }
        if field.attributedPlaceholder?.string != placeholder {
            field.placeholder = placeholder
        }
        if isFocused {
            if !field.isFirstResponder {
                field.becomeFirstResponder()
            }
        } else if field.isFirstResponder {
            field.resignFirstResponder()
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var text: Binding<String>
        var isFocused: Binding<Bool>

        init(text: Binding<String>, isFocused: Binding<Bool>) {
            self.text = text
            self.isFocused = isFocused
        }

        func makeAccessoryView() -> UIToolbar {
            let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
            toolbar.autoresizingMask = [.flexibleWidth]
            let done = UIBarButtonItem(
                title: String(localized: "完成"),
                style: .done,
                target: self,
                action: #selector(doneTapped)
            )
            toolbar.items = [UIBarButtonItem.flexibleSpace(), done]
            return toolbar
        }

        @objc func doneTapped() {
            isFocused.wrappedValue = false
        }

        @objc func changed(_ field: UITextField) {
            let next = field.text ?? ""
            guard text.wrappedValue != next else { return }
            text.wrappedValue = next
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let current = textField.text ?? ""
            guard let swiftRange = Range(range, in: current) else { return false }
            return PriceInput.isAllowed(current.replacingCharacters(in: swiftRange, with: string))
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            if !isFocused.wrappedValue {
                isFocused.wrappedValue = true
            }
            DispatchQueue.main.async {
                let end = textField.endOfDocument
                textField.selectedTextRange = textField.textRange(from: end, to: end)
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            if isFocused.wrappedValue {
                isFocused.wrappedValue = false
            }
        }
    }
}
#endif

#Preview {
    SubscriptionFormView()
        .modelContainer(PreviewContainer.sample)
        .environment(ProStore())
}
