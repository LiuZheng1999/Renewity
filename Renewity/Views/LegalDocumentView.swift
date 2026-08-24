import SwiftUI

enum LegalDocument: String, CaseIterable, Identifiable {
    case termsOfUse
    case privacyPolicy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .termsOfUse: String(localized: "使用条款")
        case .privacyPolicy: String(localized: "隐私政策")
        }
    }

    private var fileStem: String {
        switch self {
        case .termsOfUse: "TermsOfUse"
        case .privacyPolicy: "PrivacyPolicy"
        }
    }

    var markdown: String {
        for suffix in Self.preferredFileSuffixes {
            if let text = loadMarkdown("\(fileStem)-\(suffix)") {
                return text
            }
        }
        return title
    }

    private static var preferredFileSuffixes: [String] {
        var suffixes: [String] = []
        for localization in Bundle.main.preferredLocalizations {
            let suffix: String
            if localization.hasPrefix("zh-Hant") || localization == "zh-TW" || localization == "zh-HK" {
                suffix = "zh-Hant"
            } else if localization.hasPrefix("zh") {
                suffix = "zh-Hans"
            } else if localization.hasPrefix("pt") {
                suffix = "pt-BR"
            } else {
                suffix = localization
            }
            if !suffixes.contains(suffix) {
                suffixes.append(suffix)
            }
        }
        for fallback in ["en", "zh-Hans"] where !suffixes.contains(fallback) {
            suffixes.append(fallback)
        }
        return suffixes
    }

    private func loadMarkdown(_ resource: String) -> String? {
        let url = Bundle.main.url(forResource: resource, withExtension: "md", subdirectory: "Legal")
            ?? Bundle.main.url(forResource: resource, withExtension: "md")
        guard let url, let text = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }
        return text
    }
}

struct LegalDocumentView: View {
    let document: LegalDocument

    var body: some View {
        ScrollView {
            Text(attributedContent)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .textSelection(.enabled)
        }
        .background(Color.groupedBackground)
        .navigationTitle(document.title)
        .toolbarTitleDisplayMode(.inline)
    }

    private var attributedContent: AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)
        if let parsed = try? AttributedString(markdown: document.markdown, options: options) {
            return parsed
        }
        return AttributedString(document.markdown)
    }
}

#Preview("隐私政策") {
    NavigationStack {
        LegalDocumentView(document: .privacyPolicy)
    }
}
