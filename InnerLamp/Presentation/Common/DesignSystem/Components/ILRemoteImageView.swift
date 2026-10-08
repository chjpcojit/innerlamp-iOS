//
//  ILRemoteImageView.swift
//  InnerLamp
//

import ImageIO
import UIKit

/// Image view that loads its picture from a server URL string.
///
/// The view keeps whatever `backgroundColor` the caller set as the placeholder: it stays visible
/// while loading, when the string is `nil` / not a URL, and when the request fails (e.g. 404).
/// Pass the URL exactly as the API returned it — the host is the backend's LAN IP and changes per
/// network, so it must never be rebuilt on the client.
///
/// Network, decode and downsampling all run off the main actor (`decode` is `nonisolated` and awaited
/// from a main-actor task, so it executes on the cooperative pool); the main actor only assigns the
/// finished bitmap. Images are downsampled to the view's pixel size, so a large source never costs
/// full-size decode time or memory for a small thumbnail.
///
/// Decoded images are kept in a shared in-memory cache; the HTTP cache of `URLSession.shared`
/// (`Cache-Control: max-age`) covers the disk side. A new `setImage` call or a reused cell cancels
/// the previous load, so a stale response never overwrites a newer image.
///
/// A picture that arrives from the network crossfades over the placeholder (`fadeDuration`); a
/// memory-cache hit is assigned instantly so a revisited screen never flashes.
final class ILRemoteImageView: UIImageView {

    private static let memoryCache = NSCache<NSString, UIImage>()

    /// Crossfade length for a freshly downloaded image. Reduce Motion disables it.
    static let fadeDuration: TimeInterval = 0.25

    /// Called after a real image was assigned (instantly for a cache hit, inside the crossfade
    /// otherwise), so an overlay can follow the image instead of appearing before it.
    var onImageLoaded: (() -> Void)?

    private var loadTask: Task<Void, Never>?
    private var pendingURL: URL?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .scaleAspectFill
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        loadTask?.cancel()
    }

    /// Loads `urlString`; `nil` or an invalid string just clears the image (placeholder shows).
    /// A view that has no size yet (cards are configured before first layout) waits for its first
    /// layout pass so the image is downsampled to the real pixel size, not the screen size.
    func setImage(urlString: String?) {
        loadTask?.cancel()
        pendingURL = nil
        image = nil

        guard let urlString, let url = URL(string: urlString) else { return }
        if bounds.isEmpty {
            pendingURL = url
        } else {
            load(url)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let url = pendingURL, !bounds.isEmpty else { return }
        pendingURL = nil
        load(url)
    }

    private func load(_ url: URL) {
        let maxPixelSize = targetMaxPixelSize()
        let cacheKey = "\(url.absoluteString)#\(Int(maxPixelSize))" as NSString
        if let cached = Self.memoryCache.object(forKey: cacheKey) {
            image = cached
            onImageLoaded?()
            return
        }

        loadTask = Task { [weak self] in
            guard let (data, response) = try? await URLSession.shared.data(from: url),
                  (response as? HTTPURLResponse)?.statusCode == 200,
                  let prepared = await Self.decode(data, maxPixelSize: maxPixelSize),
                  !Task.isCancelled
            else { return }
            Self.memoryCache.setObject(prepared, forKey: cacheKey, cost: prepared.decodedCost)
            self?.display(prepared)
        }
    }

    private func display(_ prepared: UIImage) {
        guard window != nil, !UIAccessibility.isReduceMotionEnabled else {
            image = prepared
            onImageLoaded?()
            return
        }
        UIView.transition(with: self, duration: Self.fadeDuration, options: [.transitionCrossDissolve, .allowUserInteraction]) {
            self.image = prepared
            self.onImageLoaded?()
        }
    }

    /// Longest side in pixels the image needs. Only called once the view has a size.
    private func targetMaxPixelSize() -> CGFloat {
        let scale = window?.screen.scale ?? traitCollection.displayScale
        return max(bounds.width, bounds.height) * max(scale, 1)
    }

    /// Decodes and downsamples fully (`ShouldCacheImmediately`) so the first draw on the main thread
    /// is just a blit. `nonisolated` keeps it off the main actor.
    private nonisolated static func decode(_ data: Data, maxPixelSize: CGFloat) async -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return nil }
        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ] as CFDictionary
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

private extension UIImage {
    /// Approximate decoded byte size, used as the `NSCache` cost.
    var decodedCost: Int {
        guard let cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }
}
