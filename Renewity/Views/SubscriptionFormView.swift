import SwiftData
import SwiftUI

struct SubscriptionFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let subscription: Subscription?

    @State private var name: String
    @State private var priceText: String
    @State private var billingCycle: BillingCycle
    @State private var categoryID: String
    @State private var billingDate: Date
    @State private var billingDateKind: BillingDateKind = .next
    @State private var notes: String
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
        _priceText = State(initialValue: subscription.map { NSDecimalNumber(decimal: $0.price).stringValue } ?? "")
        _billingCycle = State(initialValue: subscription?.billingCycle ?? .monthly)
        _categoryID = State(initialValue: subscription?.categoryRaw ?? SubscriptionCategory.other.rawValue)
        if let subscription, let trialEnd = subscription.trialEndDate, subscription.isInTrial {
            _billingDate = State(initialValue: trialEnd)
            _billingDateKind = State(initialValue: .next)
        } else {
            _billingDate = State(initialValue: subscription?.upcomingBillingDate ?? .now)
        }
        _notes = State(initialValue: subscription?.notes ?? "")
        _iconName = State(initialValue: subscription?.iconName ?? "")
        _paymentMethodID = State(initialValue: PaymentMethod.normalizedID(subscription?.paymentMethodRaw ?? PaymentMethod.creditCard.rawValue))
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
        let normalized = priceText
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }
        return Decimal(string: normalized)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (parsedPrice ?? 0) > 0
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
            .sheet(isPresented: $showingPaywall, onDismiss: applyPendingBillingCurrencyIfPro) {
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
            Spacer(minLength: 8)
            TextField("0.00", text: $priceText)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .frame(minWidth: 72, maxWidth: 140)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(width: 1, height: 22)
            Button {
                showingCurrencyPicker = true
            } label: {
                HStack(spacing: 4) {
                    Text(Formatters.currencyPickerTitle(for: billingCurrencyCode))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
            .accessibilityLabel("扣费货币")
        }
        .padding(.vertical, 4)
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

            Section("基本信息") {
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
            }

            Section("费用") {
                amountRow
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

            Section {
                Toggle("订阅进行中", isOn: $isActive)
                if isActive {
                    if !hasTrial {
                        Picker("扣费日期", selection: $billingDateKind) {
                            ForEach(BillingDateKind.allCases) { kind in
                                Text(kind.title).tag(kind)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: billingDateKind) { oldKind, newKind in
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
                    }
                    DatePicker(hasTrial ? String(localized: "下次扣费") : billingDateKind.title, selection: $billingDate, displayedComponents: .date)
                        .onChange(of: billingDate) { _, newValue in
                            if hasTrial {
                                billingDateKind = .next
                                trialEndDate = newValue
                            }
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
                }
            } header: {
                Text("续费")
            } footer: {
                if !isActive {
                    Text("暂停后不再按期扣费，也不会发送提醒。")
                } else if hasTrial {
                    Text("试用持续到下次扣费日，当天开始按上面的费用扣款。")
                }
            }

            Section("提醒时间") {
                Toggle("续费提醒", isOn: remindersEnabledBinding)
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

            Section("备注") {
                TextField("可选", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .navigationTitle(isEditing ? String(localized: "编辑订阅") : String(localized: "添加订阅"))
        .scrollDismissesKeyboard(.interactively)
    }

    private static let newCategoryTag = "__new_category__"

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
        if template.suggestedPrice > 0 {
            priceText = NSDecimalNumber(decimal: template.suggestedPrice).stringValue
        } else if !isEditing {
            priceText = ""
        }
        billingCycle = template.cycle
        categoryID = template.category.rawValue
        iconName = template.isCustomDraft ? "" : template.iconName
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
        guard let price = parsedPrice else { return }
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
            subscription.iconName = resolvedIcon
            subscription.paymentMethodRaw = paymentMethodID
            subscription.customCycleValue = max(1, customCycleValue)
            subscription.customCycleUnit = customCycleUnit
            subscription.accentColorHex = accentColorHex
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
                trialReminderOffsets: hasTrial ? trialReminderDrafts.map(\.days) : []
            )
            item.categoryRaw = categoryID
            item.paymentMethodRaw = paymentMethodID
            modelContext.insert(item)
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
        switch billingDateKind {
        case .next:
            billingDate
        case .last:
            billingCycle.nextBillingDate(
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

#Preview {
    SubscriptionFormView()
        .modelContainer(PreviewContainer.sample)
        .environment(ProStore())
}
