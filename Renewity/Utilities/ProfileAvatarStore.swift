import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

enum ProfileAvatarStore {
    static let revisionKey = "profileAvatarRevision"

    private static var fileURL: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("profile-avatar.jpg")
    }

    static var hasAvatar: Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }

    static func save(_ data: Data) {
        let jpeg = compressedJPEG(from: data) ?? data
        try? jpeg.write(to: fileURL, options: .atomic)
        bumpRevision()
    }

    #if canImport(UIKit)
    static func save(_ image: UIImage) {
        let maxDimension: CGFloat = 512
        let longest = max(image.size.width, image.size.height)
        let scale = longest > maxDimension ? maxDimension / longest : 1
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        guard let jpeg = resized.jpegData(compressionQuality: 0.84) else { return }
        try? jpeg.write(to: fileURL, options: .atomic)
        bumpRevision()
    }
    #endif

    static func remove() {
        try? FileManager.default.removeItem(at: fileURL)
        bumpRevision()
    }

    static func loadImage() -> Image? {
        guard hasAvatar, let data = try? Data(contentsOf: fileURL) else { return nil }
        #if canImport(UIKit)
        guard let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
        #elseif canImport(AppKit)
        guard let nsImage = NSImage(data: data) else { return nil }
        return Image(nsImage: nsImage)
        #else
        return nil
        #endif
    }

    private static func bumpRevision() {
        let current = UserDefaults.standard.integer(forKey: revisionKey)
        UserDefaults.standard.set(current + 1, forKey: revisionKey)
    }

    private static func compressedJPEG(from data: Data) -> Data? {
        #if canImport(UIKit)
        guard let image = UIImage(data: data) else { return nil }
        let maxDimension: CGFloat = 512
        let longest = max(image.size.width, image.size.height)
        let scale = longest > maxDimension ? maxDimension / longest : 1
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.jpegData(compressionQuality: 0.84)
        #elseif canImport(AppKit)
        guard let image = NSImage(data: data) else { return nil }
        let maxDimension: CGFloat = 512
        let longest = max(image.size.width, image.size.height)
        let scale = longest > maxDimension ? maxDimension / longest : 1
        let size = NSSize(width: image.size.width * scale, height: image.size.height * scale)
        let resized = NSImage(size: size)
        resized.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size), from: .zero, operation: .copy, fraction: 1)
        resized.unlockFocus()
        guard let tiff = resized.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.84])
        #else
        return nil
        #endif
    }
}

struct ProfileAvatarView: View {
    var size: CGFloat = 32
    @AppStorage(ProfileAvatarStore.revisionKey) private var revision = 0

    var body: some View {
        Group {
            if let image = ProfileAvatarStore.loadImage() {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .scaledToFit()
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.primary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .id(revision)
        .accessibilityHidden(true)
    }
}
