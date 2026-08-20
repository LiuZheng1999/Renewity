import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

nonisolated enum ServiceIconStore {
    static let prefix = "remote:"

    static func iconName(forID id: String) -> String {
        "\(prefix)\(sanitize(id))"
    }

    static func iconName(forTrackID id: Int) -> String {
        iconName(forID: String(id))
    }

    static func fileURL(forIconName iconName: String) -> URL? {
        guard iconName.hasPrefix(prefix) else { return nil }
        let identifier = sanitize(String(iconName.dropFirst(prefix.count)))
        guard !identifier.isEmpty else { return nil }
        return directory.appendingPathComponent("\(identifier).png")
    }

    static func importArtwork(from urls: [URL], id: String) async -> String? {
        for url in urls {
            if let name = await importArtwork(from: url, id: id) {
                return name
            }
        }
        return nil
    }

    static func importArtwork(from url: URL, id: String) async -> String? {
        let name = iconName(forID: id)
        guard let destination = fileURL(forIconName: name) else { return nil }
        if FileManager.default.fileExists(atPath: destination.path) {
            return name
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard isImageData(data, response: response) else { return nil }
            try data.write(to: destination, options: .atomic)
            return name
        } catch {
            return nil
        }
    }

    static func importArtwork(from url: URL, trackID: Int) async -> String? {
        await importArtwork(from: url, id: String(trackID))
    }

    #if canImport(UIKit)
    static func importImage(_ image: UIImage, id: String) -> String? {
        let name = iconName(forID: id)
        guard let destination = fileURL(forIconName: name) else { return nil }
        let maxSide: CGFloat = 512
        let longest = max(image.size.width, image.size.height)
        let scale = longest > maxSide ? maxSide / longest : 1
        let size = CGSize(width: max(1, image.size.width * scale), height: max(1, image.size.height * scale))
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        guard let data = resized.pngData() else { return nil }
        if FileManager.default.fileExists(atPath: destination.path) {
            try? FileManager.default.removeItem(at: destination)
        }
        do {
            try data.write(to: destination, options: .atomic)
            return name
        } catch {
            return nil
        }
    }
    #endif

    #if canImport(UIKit)
    static func uiImage(named iconName: String) -> UIImage? {
        guard let url = fileURL(forIconName: iconName) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
    #endif

    #if canImport(AppKit)
    static func nsImage(named iconName: String) -> NSImage? {
        guard let url = fileURL(forIconName: iconName) else { return nil }
        return NSImage(contentsOf: url)
    }
    #endif

    private static func sanitize(_ id: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ".-_"))
        return String(id.unicodeScalars.map { allowed.contains($0) ? Character($0) : "." })
    }

    private static func isImageData(_ data: Data, response: URLResponse) -> Bool {
        guard data.count > 8 else { return false }
        if let mime = response.mimeType, mime.hasPrefix("image/") { return true }
        let bytes = [UInt8](data.prefix(12))
        if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return true }
        if bytes.starts(with: [0xFF, 0xD8, 0xFF]) { return true }
        if bytes.starts(with: [0x47, 0x49, 0x46]) { return true }
        if bytes.starts(with: [0x00, 0x00, 0x01, 0x00]) { return true }
        if bytes.starts(with: [0x00, 0x00, 0x02, 0x00]) { return true }
        if data.count > 12, let header = String(data: data.prefix(4), encoding: .ascii), header == "RIFF" {
            return true
        }
        return false
    }

    private static var directory: URL {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ServiceIcons", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
