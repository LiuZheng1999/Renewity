import SwiftUI

struct BrandPickerView: View {
    let onSelect: (SubscriptionTemplate) -> Void
    var onCustom: ((String) -> Void)?

    @State private var searchText = ""
    @State private var selectedCategory: SubscriptionCategory?
    @State private var webHits: [BrandSearchHit] = []
    @State private var isSearchingWeb = false
    @State private var loadingID: String?

    private var query: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isSearching: Bool { !query.isEmpty }

    private var localMatches: [SubscriptionTemplate] {
        var items = SubscriptionTemplate.all
        if let selectedCategory, !isSearching {
            items = items.filter { $0.category == selectedCategory }
        }
        if isSearching {
            items = items.filter { $0.searchText.localizedCaseInsensitiveContains(query) }
        }
        return items
    }

    private var grouped: [(category: SubscriptionCategory, items: [SubscriptionTemplate])] {
        SubscriptionCategory.allCases.compactMap { category in
            let items = localMatches.filter { $0.category == category }
            guard !items.isEmpty else { return nil }
            return (category, items)
        }
    }

    private var searchHits: [BrandSearchHit] {
        let localNames = Set(localMatches.map { normalize($0.name) })
        let catalogHits = localMatches.map { template in
            BrandSearchHit(
                id: "catalog:\(template.id)",
                name: template.name,
                subtitle: template.category.title,
                artworkURLs: [],
                category: template.category,
                iconID: template.logoID,
                bundledIconName: template.iconName,
                suggestedPrice: template.suggestedPrice,
                cycle: template.cycle,
                isCatalog: true
            )
        }
        let remoteHits = webHits.filter { hit in
            !localNames.contains(normalize(hit.name))
        }
        return catalogHits + remoteHits
    }

    var body: some View {
        VStack(spacing: 0) {
            if !isSearching {
                categoryFilter
                    .padding(.vertical, 8)
            }

            if isSearching {
                searchContent
            } else {
                browseContent
            }
        }
        .background(Color.groupedBackground)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "搜索任意服务"
        )
        .task(id: query) {
            await searchWeb(for: query)
        }
    }

    private var browseContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                if let onCustom {
                    Button {
                        onCustom("")
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.accentColor.gradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("自定义订阅")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("名称、金额和图标都自己填")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                    }
                    .buttonStyle(.plain)
                }

                ForEach(grouped, id: \.category) { group in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(group.category.title)
                            .font(.headline)
                            .padding(.horizontal, 20)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 14) {
                            ForEach(group.items) { template in
                                Button {
                                    onSelect(template)
                                } label: {
                                    VStack(spacing: 8) {
                                        SubscriptionIconView(
                                            iconName: template.iconName,
                                            color: template.category.color,
                                            size: 56
                                        )
                                        Text(template.name)
                                            .font(.caption2)
                                            .foregroundStyle(.primary)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.center)
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.bottom, 24)
        }
    }

    private var searchContent: some View {
        Group {
            if isSearchingWeb && searchHits.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    ProgressView()
                    Text("正在搜索")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else if searchHits.isEmpty {
                emptySearch
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(searchHits) { hit in
                            Button {
                                Task { await select(hit) }
                            } label: {
                                searchRow(hit)
                            }
                            .buttonStyle(.plain)
                            .disabled(loadingID != nil)

                            if hit.id != searchHits.last?.id {
                                Divider()
                                    .padding(.leading, 84)
                            }
                        }

                        if let onCustom, !hasExactNameMatch {
                            Divider()
                                .padding(.leading, 84)
                            Button {
                                onCustom(query)
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: "plus")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .frame(width: 52, height: 52)
                                        .background(Color.accentColor.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("添加「\(query)」")
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(.primary)
                                        Text("自定义订阅")
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private var emptySearch: some View {
        ContentUnavailableView {
            Label("没有找到「\(query)」", systemImage: "magnifyingglass")
        } description: {
            Text("可以换成网站域名再搜，或直接添加自定义订阅。")
        } actions: {
            if let onCustom {
                Button("添加「\(query)」") {
                    onCustom(query)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var hasExactNameMatch: Bool {
        searchHits.contains { $0.name.compare(query, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame }
    }

    private func searchRow(_ hit: BrandSearchHit) -> some View {
        HStack(spacing: 14) {
            ZStack {
                SubscriptionIconView(
                    iconName: hit.bundledIconName,
                    color: hit.category.color,
                    size: 52,
                    remoteURL: hit.previewURL
                )
                if loadingID == hit.id {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.black.opacity(0.28))
                    ProgressView()
                        .tint(.white)
                }
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 3) {
                Text(hit.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if !hit.subtitle.isEmpty {
                    Text(hit.subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(String(localized: "全部"), selected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(SubscriptionCategory.allCases) { category in
                    chip(category.title, selected: selectedCategory == category) {
                        selectedCategory = selectedCategory == category ? nil : category
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(selected ? Color.accentColor : Color.secondary.opacity(0.12), in: Capsule())
                .foregroundStyle(selected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }

    private func searchWeb(for query: String) async {
        guard query.count >= 2 else {
            webHits = []
            isSearchingWeb = false
            return
        }
        isSearchingWeb = true
        try? await Task.sleep(for: .milliseconds(280))
        guard !Task.isCancelled else { return }
        webHits = await BrandSearchService.searchWeb(query)
        isSearchingWeb = false
    }

    private func select(_ hit: BrandSearchHit) async {
        if hit.isCatalog {
            onSelect(hit.template(remoteIconName: nil))
            return
        }
        loadingID = hit.id
        defer { loadingID = nil }
        let iconName = await ServiceIconStore.importArtwork(from: hit.artworkURLs, id: hit.iconID)
        onSelect(hit.template(remoteIconName: iconName))
    }

    private func normalize(_ value: String) -> String {
        value.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: ".", with: "")
    }
}

#Preview {
    NavigationStack {
        BrandPickerView(onSelect: { _ in }, onCustom: { _ in })
            .navigationTitle("选择服务")
            .toolbarTitleDisplayMode(.inlineLarge)
    }
}
