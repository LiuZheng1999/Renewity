import PhotosUI
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ServiceAppearanceView: View {
    @Binding var name: String
    @Binding var iconName: String
    @Binding var accentColorHex: String
    var fallbackColor: Color
    var customIconID: String

    @State private var pickerItem: PhotosPickerItem?
    @State private var cropperItem: ServiceIconCropItem?

    var body: some View {
        Form {
            Section("预览") {
                HStack(spacing: 14) {
                    SubscriptionIconView(
                        iconName: resolvedIconName,
                        color: Color(hex: accentColorHex.isEmpty ? "5E5CE6" : accentColorHex),
                        size: 52
                    )
                    Text(name.isEmpty ? String(localized: "未命名订阅") : name)
                        .font(.headline)
                    Spacer()
                }
                .padding(.vertical, 6)
                .listRowBackground(rowBackground)
            }

            Section("名称") {
                TextField("订阅名称", text: $name)
            }

            Section("背景色") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                    Button {
                        accentColorHex = ""
                    } label: {
                        Circle()
                            .strokeBorder(Color.secondary.opacity(0.35), lineWidth: 1)
                            .background(Circle().fill(Color.groupedBackground))
                            .frame(width: 32, height: 32)
                            .overlay {
                                if accentColorHex.isEmpty {
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundStyle(.primary)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("默认")

                    ForEach(CategoryColorPreset.allCases) { preset in
                        Button {
                            accentColorHex = preset.hex
                        } label: {
                            Circle()
                                .fill(preset.color.gradient)
                                .frame(width: 32, height: 32)
                                .overlay {
                                    if accentColorHex.caseInsensitiveCompare(preset.hex) == .orderedSame {
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
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label("从相册选择", systemImage: "photo")
                }
                .foregroundStyle(.primary)

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
                                    iconName == icon ? selectedSwatch : Color.secondary.opacity(0.12),
                                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("服务")
        .toolbarTitleDisplayMode(.inline)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                defer { pickerItem = nil }
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                let prepared = ImageCropView.preparedSource(image)
                try? await Task.sleep(for: .milliseconds(350))
                await MainActor.run {
                    cropperItem = ServiceIconCropItem(image: prepared)
                }
            }
        }
        .fullScreenCover(item: $cropperItem) { item in
            ImageCropView(
                sourceImage: item.image,
                onCancel: { cropperItem = nil },
                onComplete: { cropped in
                    if let stored = ServiceIconStore.importImage(cropped, id: customIconID) {
                        iconName = stored
                    }
                    cropperItem = nil
                }
            )
        }
    }

    private var resolvedIconName: String {
        iconName.isEmpty ? "creditcard.fill" : iconName
    }

    private var selectedSwatch: Color {
        accentColorHex.isEmpty ? fallbackColor : Color(hex: accentColorHex)
    }

    private var rowBackground: Color {
        if accentColorHex.isEmpty {
            return Color.groupedSecondary
        }
        return Color(hex: accentColorHex).opacity(0.22)
    }
}

private struct ServiceIconCropItem: Identifiable {
    let id = UUID()
    let image: UIImage
}
