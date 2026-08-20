import SwiftData
import SwiftUI

struct CategoryManageView: View {
    @Query(sort: \AppCategory.sortOrder) private var categories: [AppCategory]
    @Query private var subscriptions: [Subscription]
    @Environment(\.modelContext) private var modelContext

    @State private var showingAdd = false
    @State private var editingCategory: AppCategory?
    @State private var showingPaywall = false
    @Environment(ProStore.self) private var proStore

    private var builtIn: [AppCategory] {
        categories.filter(\.isBuiltIn)
    }

    private var custom: [AppCategory] {
        categories.filter { !$0.isBuiltIn }
    }

    var body: some View {
        List {
            Section {
                ForEach(builtIn) { category in
                    categoryRow(category)
                }
            } header: {
                Text("系统分类")
            } footer: {
                Text("系统分类不能删除，可在添加订阅时直接使用。")
            }

            Section {
                if custom.isEmpty {
                    Text("还没有自定义分类")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(custom) { category in
                        Button {
                            editingCategory = category
                        } label: {
                            categoryRow(category)
                        }
                    }
                    .onDelete(perform: deleteCustom)
                }
            } header: {
                Text("我的分类")
            }
        }
        .navigationTitle("分类")
        .toolbarTitleDisplayMode(.inlineLarge)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if proStore.isPro {
                        showingAdd = true
                    } else {
                        showingPaywall = true
                    }
                } label: {
                    Label("新建分类", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            CategoryFormView()
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .sheet(isPresented: Binding(
            get: { editingCategory != nil },
            set: { if !$0 { editingCategory = nil } }
        )) {
            if let editingCategory {
                CategoryFormView(category: editingCategory)
            }
        }
    }

    private func categoryRow(_ category: AppCategory) -> some View {
        HStack(spacing: 12) {
            Image(systemName: category.iconName)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(category.color.gradient, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(category.localizedName)
                .foregroundStyle(.primary)
            Spacer()
            Text("\(usageCount(for: category))")
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private func usageCount(for category: AppCategory) -> Int {
        subscriptions.filter { $0.categoryRaw == category.identifier }.count
    }

    private func deleteCustom(at offsets: IndexSet) {
        let otherID = SubscriptionCategory.other.rawValue
        for index in offsets {
            let category = custom[index]
            for subscription in subscriptions where subscription.categoryRaw == category.identifier {
                subscription.categoryRaw = otherID
            }
            modelContext.delete(category)
        }
    }
}

#Preview {
    NavigationStack {
        CategoryManageView()
    }
    .modelContainer(PreviewContainer.sample)
    .environment(ProStore())
}
