import SwiftData
import SwiftUI

struct CategoryFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \AppCategory.sortOrder) private var categories: [AppCategory]

    private let category: AppCategory?
    var onSave: ((AppCategory) -> Void)?

    @State private var name: String
    @State private var iconName: String
    @State private var colorHex: String

    init(category: AppCategory? = nil, onSave: ((AppCategory) -> Void)? = nil) {
        self.category = category
        self.onSave = onSave
        _name = State(initialValue: category?.name ?? "")
        _iconName = State(initialValue: category?.iconName ?? "tag.fill")
        _colorHex = State(initialValue: category?.colorHex ?? CategoryColorPreset.indigo.hex)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("预览") {
                    HStack(spacing: 12) {
                        Image(systemName: iconName)
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color(hex: colorHex).gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        Text(name.isEmpty ? String(localized: "新分类") : name)
                            .font(.headline)
                    }
                }

                Section("名称") {
                    TextField("例如：宠物、保险、出行", text: $name)
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
                        ForEach(CategoryIconLibrary.all, id: \.self) { icon in
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
            .navigationTitle(category == nil ? String(localized: "新建分类") : String(localized: "编辑分类"))
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
        let item: AppCategory

        if let category {
            category.name = trimmed
            category.iconName = iconName
            category.colorHex = colorHex
            item = category
        } else {
            let nextOrder = (categories.map(\.sortOrder).max() ?? 0) + 1
            item = AppCategory(
                name: trimmed,
                iconName: iconName,
                colorHex: colorHex,
                isBuiltIn: false,
                sortOrder: nextOrder
            )
            modelContext.insert(item)
        }

        onSave?(item)
        dismiss()
    }
}

#Preview {
    CategoryFormView()
        .modelContainer(PreviewContainer.sample)
}
