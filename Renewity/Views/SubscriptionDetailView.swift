import SwiftData
import SwiftUI

struct SubscriptionDetailView: View {
    @Bindable var subscription: Subscription
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appCategories) private var categories
    @Environment(\.appPaymentMethods) private var paymentMethods

    @State private var showingEdit = false
    @State private var confirmDelete = false

    var body: some View {
        List {
            Section {
                header
                    .listRowInsets(EdgeInsets(top: 24, leading: 16, bottom: 24, trailing: 16))
                    .listRowBackground(Color.clear)
                    .frame(maxWidth: .infinity)
            }

            Section("费用") {
                LabeledContent("每次扣费", value: Formatters.currency(subscription.price, code: subscription.resolvedCurrencyCode))
                LabeledContent("计费周期", value: subscription.cycleDisplayTitle)
                LabeledContent("折合每月", value: Formatters.currency(subscription.monthlyCost, code: subscription.resolvedCurrencyCode))
                LabeledContent("折合每年", value: Formatters.currency(subscription.yearlyCost, code: subscription.resolvedCurrencyCode))
            }

            Section("续费") {
                LabeledContent("下次扣费", value: Formatters.mediumDate(subscription.upcomingBillingDate))
                LabeledContent("剩余时间", value: Formatters.billingRelative(subscription.upcomingBillingDate))
                LabeledContent("续费提醒", value: subscription.reminderSummary)
            }

            if subscription.trialEndDate != nil {
                Section("试用期") {
                    LabeledContent("试用到期", value: Formatters.mediumDate(subscription.trialEndDate ?? Date()))
                    LabeledContent("状态", value: subscription.isInTrial ? String(localized: "试用中") : String(localized: "试用已结束"))
                    LabeledContent("试用提醒", value: subscription.trialReminderSummary)
                }
            }

            Section("信息") {
                LabeledContent("支付方式", value: subscription.resolvedPaymentMethod(in: paymentMethods).localizedName)
                LabeledContent("分类", value: subscription.resolvedCategory(in: categories).localizedName)
                LabeledContent("状态", value: subscription.isActive ? String(localized: "进行中") : String(localized: "已暂停"))
                if !subscription.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("备注")
                            .foregroundStyle(.secondary)
                        Text(subscription.notes)
                    }
                }
            }

            Section {
                Button(subscription.isActive ? String(localized: "暂停订阅") : String(localized: "恢复订阅")) {
                    subscription.isActive.toggle()
                    ReminderService.reschedule(for: subscription)
                }

                Button("删除订阅", role: .destructive) {
                    confirmDelete = true
                }
            }
        }
        .navigationTitle(subscription.name)
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("编辑") {
                    showingEdit = true
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            SubscriptionFormView(subscription: subscription)
        }
        .confirmationDialog("删除订阅", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("删除「\(subscription.name)」", role: .destructive) {
                ReminderService.cancel(id: subscription.id)
                modelContext.delete(subscription)
                dismiss()
            }
        } message: {
            Text("删除后无法恢复。")
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            SubscriptionIconView(
                iconName: subscription.iconName,
                color: subscription.resolvedCategory(in: categories).color,
                size: 76
            )
            Text(subscription.name)
                .font(.title2.weight(.bold))
            if subscription.isInTrial {
                HStack(spacing: 4) {
                    Text("试用中")
                    Text(verbatim: "·")
                    Text(Formatters.trialRelative(subscription.nextRelevantDate))
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.orange)
            }
            Text(verbatim: "\(Formatters.currency(subscription.price, code: subscription.resolvedCurrencyCode)) / \(subscription.cycleDisplayTitle)")
                .font(.title3)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        SubscriptionDetailView(
            subscription: Subscription(
                name: "Netflix",
                price: 15.49,
                category: .entertainment,
                iconName: "logo_netflix"
            )
        )
    }
    .modelContainer(PreviewContainer.sample)
}
