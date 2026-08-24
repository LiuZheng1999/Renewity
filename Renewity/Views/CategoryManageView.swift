import SwiftData
import SwiftUI

struct CategoryManageView: View {
    @Query(sort: \AppCategory.sortOrder) private var categories: [AppCategory]
    @Query private var subscriptions: [Subscription]
    @Environment(\.modelContext) private var modelContext

    @State private var showingAdd = false
    @State private var editingCategory: AppCategory?
    @State private var showingPaywall = false
    @State private var editMode: EditMode = .inactive
    @Environment(ProStore.self) private var proStore

    private var canDelete: Bool {
        categories.count > 1
    }

    private var isEditing: Bool {
        editMode.isEditing
    }

    var body: some View {
        List {
            Section {
                ForEach(categories) { category in
                    categoryRow(category)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard !isEditing else { return }
                            editingCategory = category
                        }
                        .deleteDisabled(!canDelete)
                }
                .onMove(perform: move)
                .onDelete(perform: delete)
            } footer: {
                Text("轻点可编辑。点「编辑」后可拖动排序或删除。至少保留一个分类；删除后，该分类下的订阅会改到剩余分类。")
            }
        }
        .environment(\.editMode, $editMode)
        .navigationTitle("分类")
        .toolbarTitleDisplayMode(.inlineLarge)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("新建", systemImage: "plus") {
                    if proStore.isPro {
                        showingAdd = true
                    } else {
                        showingPaywall = true
                    }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(isEditing ? "完成" : "编辑") {
                    withAnimation {
                        editMode = isEditing ? .inactive : .active
                    }
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            CategoryFormView()
        }
        .sheet(isPresented: Binding(
            get: { editingCategory != nil },
            set: { if !$0 { editingCategory = nil } }
        )) {
            if let editingCategory {
                CategoryFormView(category: editingCategory)
            }
        }
        .fullScreenCover(isPresented: $showingPaywall) {
            PaywallView()
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

    private func move(from source: IndexSet, to destination: Int) {
        var ordered = Array(categories)
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, item) in ordered.enumerated() {
            item.sortOrder = index
        }
        try? modelContext.save()
    }

    private func delete(at offsets: IndexSet) {
        guard canDelete else { return }
        var remaining = categories
        for category in offsets.map({ categories[$0] }) {
            guard remaining.count > 1 else { break }
            AppCategory.delete(
                category,
                subscriptions: subscriptions,
                remaining: remaining,
                in: modelContext
            )
            remaining.removeAll { $0.identifier == category.identifier }
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
