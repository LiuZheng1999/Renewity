import SwiftUI
import UIKit

/// 固定正方形裁剪框：拖动 / 双指缩放图片，确认后输出裁剪结果
struct ImageCropView: View {
    let sourceImage: UIImage
    let onCancel: () -> Void
    let onComplete: (UIImage) -> Void

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var fittedBaseScale: CGFloat = 1

    private let cropRatio: CGFloat = 1

    var body: some View {
        GeometryReader { geometry in
            let cropSide = min(geometry.size.width, geometry.size.height) * 0.78
            let cropSize = CGSize(width: cropSide, height: cropSide / cropRatio)
            let cropRect = CGRect(
                x: (geometry.size.width - cropSize.width) / 2,
                y: (geometry.size.height - cropSize.height) / 2,
                width: cropSize.width,
                height: cropSize.height
            )

            ZStack {
                Color.black.ignoresSafeArea()

                Image(uiImage: sourceImage)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .gesture(
                        SimultaneousGesture(
                            dragGesture(cropRect: cropRect, imageDisplaySize: displaySize(in: geometry.size)),
                            magnificationGesture(cropRect: cropRect, imageDisplaySize: displaySize(in: geometry.size))
                        )
                    )

                cropMask(cropRect: cropRect, in: geometry.size)
                    .allowsHitTesting(false)

                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.white, lineWidth: 1.5)
                    .frame(width: cropSize.width, height: cropSize.height)
                    .position(x: cropRect.midX, y: cropRect.midY)
                    .allowsHitTesting(false)

                VStack {
                    HStack {
                        Button("取消", action: onCancel)
                            .foregroundStyle(.white)
                        Spacer()
                        Button("完成") {
                            if let cropped = renderCroppedImage(cropRect: cropRect, containerSize: geometry.size) {
                                onComplete(cropped)
                            }
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, max(geometry.safeAreaInsets.top, 12))

                    Spacer()

                    Text("拖动并缩放图片以调整裁剪区域")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.bottom, max(geometry.safeAreaInsets.bottom, 16) + 12)
                }
            }
            .onAppear {
                initializeFit(containerSize: geometry.size, cropSize: cropSize)
            }
            .onChange(of: geometry.size) { _, newSize in
                initializeFit(containerSize: newSize, cropSize: cropSize)
            }
        }
        .ignoresSafeArea()
        .interactiveDismissDisabled()
        .statusBarHidden()
    }

    private func displaySize(in container: CGSize) -> CGSize {
        let imageSize = sourceImage.size
        guard imageSize.width > 0, imageSize.height > 0 else { return .zero }
        let fit = min(container.width / imageSize.width, container.height / imageSize.height)
        return CGSize(width: imageSize.width * fit, height: imageSize.height * fit)
    }

    private func initializeFit(containerSize: CGSize, cropSize: CGSize) {
        let shown = displaySize(in: containerSize)
        guard shown.width > 0, shown.height > 0 else { return }
        let cover = max(cropSize.width / shown.width, cropSize.height / shown.height)
        fittedBaseScale = cover
        scale = cover
        lastScale = cover
        offset = .zero
        lastOffset = .zero
    }

    private func dragGesture(cropRect: CGRect, imageDisplaySize: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                offset = clampedOffset(cropRect: cropRect, imageDisplaySize: imageDisplaySize, proposed: offset)
                lastOffset = offset
            }
    }

    private func magnificationGesture(cropRect: CGRect, imageDisplaySize: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = max(fittedBaseScale, lastScale * value.magnification)
            }
            .onEnded { _ in
                scale = max(fittedBaseScale, scale)
                lastScale = scale
                offset = clampedOffset(cropRect: cropRect, imageDisplaySize: imageDisplaySize, proposed: offset)
                lastOffset = offset
            }
    }

    private func clampedOffset(cropRect: CGRect, imageDisplaySize: CGSize, proposed: CGSize) -> CGSize {
        let scaledWidth = imageDisplaySize.width * scale
        let scaledHeight = imageDisplaySize.height * scale
        let maxX = max(0, (scaledWidth - cropRect.width) / 2)
        let maxY = max(0, (scaledHeight - cropRect.height) / 2)
        return CGSize(
            width: min(max(proposed.width, -maxX), maxX),
            height: min(max(proposed.height, -maxY), maxY)
        )
    }

    private func cropMask(cropRect: CGRect, in size: CGSize) -> some View {
        Canvas { context, _ in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black.opacity(0.55)))
            context.blendMode = .clear
            context.fill(Path(cropRect), with: .color(.white))
        }
        .compositingGroup()
        .allowsHitTesting(false)
    }

    private func renderCroppedImage(cropRect: CGRect, containerSize: CGSize) -> UIImage? {
        let imageSize = sourceImage.size
        guard imageSize.width > 0, imageSize.height > 0 else { return nil }

        let fit = min(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
        let drawnSize = CGSize(width: imageSize.width * fit * scale, height: imageSize.height * fit * scale)
        let imageOrigin = CGPoint(
            x: (containerSize.width - drawnSize.width) / 2 + offset.width,
            y: (containerSize.height - drawnSize.height) / 2 + offset.height
        )

        let scaleX = imageSize.width / drawnSize.width
        let scaleY = imageSize.height / drawnSize.height
        var pixelRect = CGRect(
            x: (cropRect.minX - imageOrigin.x) * scaleX,
            y: (cropRect.minY - imageOrigin.y) * scaleY,
            width: cropRect.width * scaleX,
            height: cropRect.height * scaleY
        )
        pixelRect = pixelRect.intersection(CGRect(origin: .zero, size: imageSize))
        guard pixelRect.width > 1, pixelRect.height > 1 else {
            return nil
        }

        let normalized = Self.normalizeOrientation(sourceImage)
        guard let normalizedCG = normalized.cgImage else { return nil }

        let outputSide: CGFloat = 900
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: outputSide, height: outputSide), format: format)
        return renderer.image { _ in
            let drawRect = CGRect(
                x: -pixelRect.minX / pixelRect.width * outputSide,
                y: -pixelRect.minY / pixelRect.height * outputSide,
                width: normalized.size.width / pixelRect.width * outputSide,
                height: normalized.size.height / pixelRect.height * outputSide
            )
            UIImage(cgImage: normalizedCG, scale: 1, orientation: .up).draw(in: drawRect)
        }
    }

    static func preparedSource(_ image: UIImage) -> UIImage {
        let normalized = normalizeOrientation(image)
        let maxSide: CGFloat = 4096
        let longest = max(normalized.size.width, normalized.size.height)
        guard longest > maxSide else { return normalized }
        let ratio = maxSide / longest
        let size = CGSize(width: normalized.size.width * ratio, height: normalized.size.height * ratio)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            normalized.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    private static func normalizeOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = image.scale
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
}
