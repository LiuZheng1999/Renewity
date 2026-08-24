import StoreKit
import SwiftUI
import UIKit

struct PaywallView: View {
    @Environment(ProStore.self) private var proStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var selected: Plan?
    @State private var isLoadingProducts = false
    @State private var legalDocument: LegalDocument?

    enum Plan: String, CaseIterable, Identifiable {
        case lifetime
        case yearly
        case monthly

        var id: String { rawValue }

        var sortOrder: Int {
            switch self {
            case .lifetime: 0
            case .yearly: 1
            case .monthly: 2
            }
        }

        var title: String {
            switch self {
            case .monthly: String(localized: "月度")
            case .yearly: String(localized: "年度")
            case .lifetime: String(localized: "终身")
            }
        }
    }

    var body: some View {
        ZStack {
            PurchasePaywallBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 15) {
                        brandHeader
                            .padding(.top, 28)

                        if proStore.isPro {
                            unlockedBanner
                                .padding(.horizontal, 20)
                        } else {
                            featuresCard
                                .padding(.horizontal, 10)

                            if visiblePlans.isEmpty {
                                loadingOrErrorState
                                    .padding(.horizontal, 10)
                            } else {
                                plansCard
                                    .padding(.horizontal, 10)

                                continueButton
                                    .padding(.horizontal, 20)

                                if let errorMessage = proStore.errorMessage {
                                    Text(errorMessage)
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 28)
                                }

                                legalFooter
                                    .padding(.horizontal, 28)
                                    .padding(.top, 4)
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .presentationBackground {
            PurchasePaywallBackground()
        }
        .task {
            if proStore.monthlyProduct == nil,
               proStore.yearlyProduct == nil,
               proStore.lifetimeProduct == nil {
                isLoadingProducts = true
                await proStore.loadProducts()
                isLoadingProducts = false
            }
            syncSelectedPlan()
        }
        .onAppear(perform: syncSelectedPlan)
        .onChange(of: proStore.products.map(\.id)) { _, _ in
            syncSelectedPlan()
        }
        .sheet(item: $legalDocument) { document in
            NavigationStack {
                LegalDocumentView(document: document)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("关闭") { legalDocument = nil }
                        }
                    }
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                if #available(iOS 26.0, *) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                        .glassEffect(.clear)
                }
            }
            .accessibilityLabel(Text("关闭"))

            Spacer()

            if !proStore.isPro {
                Button("恢复购买") {
                    Task { await proStore.restore() }
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .disabled(proStore.isLoading || isLoadingProducts)
            }
        }
    }

    private var brandHeader: some View {
        HStack(spacing: 10) {
            Text(AppConfig.appName)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.primary)

            Text("Pro")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.black))
        }
        .frame(maxWidth: .infinity)
    }

    private var featuresCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            featureRow(
                title: String(localized: "无限订阅"),
                detail: String(localized: "免费版最多 \(AppConfig.freeSubscriptionLimit) 个，Pro 不限数量")
            )
            featureRow(
                title: String(localized: "多货币"),
                detail: String(localized: "改默认货币、付款货币，并把合计换算到其他货币")
            )
            featureRow(
                title: String(localized: "自定义分类"),
                detail: String(localized: "按自己的方式整理订阅")
            )
            featureRow(
                title: String(localized: "多次提醒"),
                detail: String(localized: "免费版 \(ReminderLead.freeCount) 次，Pro 最多 \(ReminderLead.maxCount) 次")
            )
            featureRow(
                title: String(localized: "云备份"),
                detail: String(localized: "iPhone 与 iPad 同步，还可备份到 iCloud 云盘")
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(colorScheme == .dark ? 0.06 : 0.01))
                }
        }
    }

    private func featureRow(title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color(uiColor: .tertiaryLabel))
                .frame(width: 16, height: 18)

            Text(featureAttributed(title: title, detail: detail))
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func featureAttributed(title: String, detail: String) -> AttributedString {
        var result = AttributedString(title)
        result.font = .system(size: 16, weight: .semibold)

        var separator = AttributedString(" — ")
        separator.foregroundColor = .secondary
        separator.font = .system(size: 15, weight: .regular)

        var detailPart = AttributedString(detail)
        detailPart.foregroundColor = .secondary
        detailPart.font = .system(size: 15, weight: .regular)

        result += separator
        result += detailPart
        return result
    }

    private var plansCard: some View {
        VStack(spacing: 5) {
            ForEach(visiblePlans) { plan in
                if let product = product(for: plan) {
                    PurchasePlanOptionRow(
                        product: product,
                        plan: plan,
                        isSelected: selected == plan
                    ) {
                        selected = plan
                    }
                }
            }
        }
        .padding(15)
        .padding(.top, 10)
        .background {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(Color(uiColor: colorScheme == .dark ? .secondarySystemGroupedBackground : .systemBackground))
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.25 : 0.15), radius: 20, y: 8)
        }
    }

    private var visiblePlans: [Plan] {
        Plan.allCases
            .filter { product(for: $0) != nil }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private var selectedProduct: Product? {
        guard let selected else { return nil }
        return product(for: selected)
    }

    private var continueButton: some View {
        Button {
            guard let product = selectedProduct, !proStore.isLoading else { return }
            Task { await proStore.purchase(product) }
        } label: {
            HStack(spacing: 8) {
                if proStore.isLoading {
                    ProgressView()
                        .tint(Color(uiColor: .systemBackground))
                } else {
                    Text("继续")
                        .font(.system(size: 20, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                }
            }
            .foregroundStyle(Color(uiColor: .systemBackground))
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(Color.primary, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(selectedProduct == nil || proStore.isLoading)
        .opacity(selectedProduct == nil ? 0.5 : 1)
    }

    private var legalFooter: some View {
        VStack(spacing: 10) {
            Text(agreeAttributedText)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .tint(.primary)
                .environment(\.openURL, OpenURLAction { url in
                    if url.host == "privacy" {
                        legalDocument = .privacyPolicy
                    } else if url.host == "terms" {
                        legalDocument = .termsOfUse
                    }
                    return .handled
                })

            Button {
                Task { await proStore.restore() }
            } label: {
                Text(restoreAttributedText)
                    .font(.system(size: 12))
                    .multilineTextAlignment(.center)
            }
            .buttonStyle(.plain)
            .disabled(proStore.isLoading || isLoadingProducts)
        }
    }

    private var agreeAttributedText: AttributedString {
        var text = AttributedString(String(localized: "继续即表示你同意"))
        text += AttributedString(" ")

        var privacy = AttributedString(String(localized: "隐私政策"))
        privacy.link = URL(string: "renewity://privacy")
        privacy.underlineStyle = .single
        text += privacy

        text += AttributedString(String(localized: "和"))

        var terms = AttributedString(String(localized: "用户协议"))
        terms.link = URL(string: "renewity://terms")
        terms.underlineStyle = .single
        text += terms

        return text
    }

    private var restoreAttributedText: AttributedString {
        var text = AttributedString(String(localized: "已经购买过？"))
        text.foregroundColor = .secondary

        var action = AttributedString(String(localized: "恢复购买"))
        action.foregroundColor = .primary
        action.underlineStyle = .single

        text += action
        return text
    }

    private var unlockedBanner: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 40))
                .foregroundStyle(.green)
            Text("已解锁全部功能")
                .font(.headline)
                .multilineTextAlignment(.center)
            Button {
                dismiss()
            } label: {
                Text("完成")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(uiColor: .systemBackground))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.primary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
        }
    }

    private var loadingOrErrorState: some View {
        VStack(spacing: 10) {
            if isLoadingProducts {
                ProgressView("正在加载套餐")
            } else {
                Text("暂时无法连接到 App Store")
                    .foregroundStyle(.secondary)
                if let error = proStore.errorMessage {
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private func product(for plan: Plan) -> Product? {
        switch plan {
        case .monthly: proStore.monthlyProduct
        case .yearly: proStore.yearlyProduct
        case .lifetime: proStore.lifetimeProduct
        }
    }

    private func syncSelectedPlan() {
        if selected == nil {
            if proStore.lifetimeProduct != nil {
                selected = .lifetime
            } else if proStore.yearlyProduct != nil {
                selected = .yearly
            } else if proStore.monthlyProduct != nil {
                selected = .monthly
            }
            return
        }
        guard let selected else { return }
        if product(for: selected) == nil {
            self.selected = proStore.lifetimeProduct != nil
                ? .lifetime
                : (proStore.yearlyProduct != nil ? .yearly : (proStore.monthlyProduct != nil ? .monthly : nil))
        }
    }
}

private struct PurchasePlanOptionRow: View {
    let product: Product
    let plan: PaywallView.Plan
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? Color(uiColor: .systemBackground) : Color(uiColor: .tertiaryLabel))

                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .center, spacing: 6) {
                        Text(plan.title)
                            .font(.system(size: 16, weight: .semibold))
                        if plan == .yearly {
                            YearlyTrialBadge()
                        }
                    }
                    Text(planSubtitle)
                        .font(.system(size: 13, weight: .regular))
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 7) {
                    Text(product.displayPrice)
                        .font(.system(size: 16, weight: .semibold))
                    if let trailing = priceTrailingLabel {
                        Text(trailing)
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
            }
            .foregroundStyle(isSelected ? Color(uiColor: .systemBackground) : .primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 21)
            .background {
                RoundedRectangle(cornerRadius: 27)
                    .fill(isSelected ? AnyShapeStyle(Color.primary) : AnyShapeStyle(Color.clear))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 27)
                    .strokeBorder(Color(uiColor: .secondaryLabel), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var planSubtitle: String {
        switch plan {
        case .lifetime:
            String(localized: "一次买断")
        case .monthly:
            product.displayPrice + String(localized: "paywall.price.perMonth", defaultValue: "/月")
        case .yearly:
            product.displayPrice + String(localized: "paywall.price.perYear", defaultValue: "/年")
        }
    }

    private var priceTrailingLabel: String? {
        switch plan {
        case .lifetime: nil
        case .monthly: String(localized: "每月")
        case .yearly: String(localized: "每年")
        }
    }
}

private struct YearlyTrialBadge: View {
    private let fill = Color(red: 0.16, green: 0.05, blue: 0.32)
    private let ink = Color(red: 0.80, green: 0.70, blue: 0.96)
    private let grid = Color(red: 0.52, green: 0.38, blue: 0.78).opacity(0.42)

    var body: some View {
        Text("7天免费试用")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule(style: .continuous)
                    .fill(fill)
                    .overlay {
                        TrialBadgeGrid(color: grid, step: 3.5)
                            .clipShape(Capsule(style: .continuous))
                    }
            }
            .fixedSize()
            .accessibilityLabel("7天免费试用")
    }
}

private struct TrialBadgeGrid: View {
    let color: Color
    let step: CGFloat

    var body: some View {
        Canvas { context, size in
            var path = Path()
            var x: CGFloat = 0
            while x <= size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += step
            }
            var y: CGFloat = 0
            while y <= size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += step
            }
            context.stroke(path, with: .color(color), lineWidth: 0.4)
        }
        .allowsHitTesting(false)
    }
}

private struct PurchasePaywallBackground: View {
    var body: some View {
        Color.paywallGradient
            .ignoresSafeArea()
    }
}

#Preview {
    PaywallView()
        .environment(ProStore())
}
