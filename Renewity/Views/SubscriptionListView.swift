import SwiftData
import SwiftUI

struct SubscriptionListView: View {
    @Query(sort: \Subscription.name) private var subscriptions: [Subscription]
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currencyCode") private var currencyCode = "CNY"
    @Environment(ExchangeRateStore.self) private var exchangeRates

    @State private var searchText = ""
    @State private var selectedCategoryID: String?
    @State private var sort: SortOption = .upcoming
    @State private var showingAdd = false
    @State private var showingCategoryForm = false
    @State private var showingPaywall = false
    @Environment(ProStore.self) private var proStore

    @Environment(\.appCategories) private var categories

    enum SortOption: String, CaseIterable, Identifiable {
        case upcoming
        case price
        case name

        var id: String { rawValue }

        var title: String {
            switch self {
            case .upcoming: String(localized: "续费日期")
            case .price: String(localized: "月均金额")
            case .name: String(localized: "名称")
            }
        }
    }

    private var filtered: [Subscription] {
        var items = subscriptions

        if let selectedCategoryID {
            items = items.filter { $0.categoryRaw == selectedCategoryID }
        }

        if !searchText.isEmpty {
            items = items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        switch sort {
        case .upcoming:
            items.sort { $0.nextRelevantDate < $1.nextRelevantDate }
        case .price:
            items.sort {
                (exchangeRates.convertedMonthlyCost(of: $0, to: currencyCode) ?? 0)
                    > (exchangeRates.convertedMonthlyCost(of: $1, to: currencyCode) ?? 0)
            }
        case .name:
            items.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
        }

        return items
    }

    private var activeItems: [Subscription] {
        filtered.filter(\.isActive)
    }

    private var pausedItems: [Subscription] {
        filtered.filter { !$0.isActive }
    }

    var body: some View {
        NavigationStack {
            Group {
                if subscriptions.isEmpty {
                    ContentUnavailableView {
                        Label("还没有订阅", systemImage: "rectangle.stack")
                    } description: {
                        Text("添加第一笔订阅，开始跟踪每月固定支出。")
                    } actions: {
                        Button("添加订阅") {
                            presentAdd()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    listContent
                }
            }
            .navigationTitle("订阅")
            .toolbarTitleDisplayMode(.inlineLarge)
            .searchable(text: $searchText, prompt: "搜索订阅")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Menu {
                        Picker("排序", selection: $sort) {
                            ForEach(SortOption.allCases) { option in
                                Text(option.title).tag(option)
                            }
                        }
                    } label: {
                        Label("排序", systemImage: "arrow.up.arrow.down")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        presentAdd()
                    } label: {
                        Label("添加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                SubscriptionFormView()
            }
            .sheet(isPresented: $showingCategoryForm) {
                CategoryFormView()
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    private func presentAdd() {
        if proStore.canAddSubscription(currentCount: subscriptions.count) {
            showingAdd = true
        } else {
            showingPaywall = true
        }
    }

    private func presentNewCategory() {
        if proStore.isPro {
            showingCategoryForm = true
        } else {
            showingPaywall = true
        }
    }

    private var listContent: some View {
        List {
            if !subscriptions.isEmpty {
                Section {
                    categoryFilter
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                }
            }

            if activeItems.isEmpty && pausedItems.isEmpty {
                ContentUnavailableView.search(text: searchText.isEmpty ? (categories.first { $0.identifier == selectedCategoryID }?.localizedName ?? "") : searchText)
            } else {
                if !activeItems.isEmpty {
                    Section("进行中 · \(activeItems.count)") {
                        ForEach(activeItems) { subscription in
                            row(for: subscription)
                        }
                    }
                }

                if !pausedItems.isEmpty {
                    Section("已暂停 · \(pausedItems.count)") {
                        ForEach(pausedItems) { subscription in
                            row(for: subscription)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: String(localized: "全部"), isSelected: selectedCategoryID == nil) {
                    selectedCategoryID = nil
                }

                ForEach(categories, id: \.identifier) { category in
                    filterChip(title: category.localizedName, isSelected: selectedCategoryID == category.identifier) {
                        selectedCategoryID = selectedCategoryID == category.identifier ? nil : category.identifier
                    }
                }

                Button {
                    presentNewCategory()
                } label: {
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.secondary.opacity(0.12), in: Capsule())
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("新建分类")
            }
        }
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.12), in: Capsule())
                .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }

    private func row(for subscription: Subscription) -> some View {
        NavigationLink {
            SubscriptionDetailView(subscription: subscription)
        } label: {
            SubscriptionRowView(subscription: subscription)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("删除", role: .destructive) {
                delete(subscription)
            }
        }
        .swipeActions(edge: .leading) {
            Button(subscription.isActive ? String(localized: "暂停") : String(localized: "恢复")) {
                subscription.isActive.toggle()
                ReminderService.reschedule(for: subscription)
            }
            .tint(subscription.isActive ? .orange : .green)
        }
        .contextMenu {
            Button(subscription.isActive ? String(localized: "暂停") : String(localized: "恢复"), systemImage: subscription.isActive ? "pause.fill" : "play.fill") {
                subscription.isActive.toggle()
                ReminderService.reschedule(for: subscription)
            }
            Button("删除", systemImage: "trash", role: .destructive) {
                delete(subscription)
            }
        }
    }

    private func delete(_ subscription: Subscription) {
        ReminderService.cancel(id: subscription.id)
        modelContext.delete(subscription)
    }
}

#Preview {
    SubscriptionListView()
        .modelContainer(PreviewContainer.sample)
        .environment(ProStore())
        .environment(ExchangeRateStore())
}
