//
//  ILStretchyHeaderView.swift
//  InnerLamp
//

import UIKit

/// Base class for the image hero at the top of a scrolling detail screen (temple, deity...).
///
/// The screen forwards `scrollViewDidScroll` to `update(contentOffsetY:)` and the header does the rest:
/// - **Pinned image**: the image keeps its top edge glued to the top of the screen. Pulling down
///   (negative offset) scales it up from the top instead of letting it slide down with the content.
/// - **Rest state**: offset `0` → identity transform, nothing changes.
/// - **Blur progress**: once the content has scrolled past 50% of `imageHeight`, `onBlurProgress`
///   reports 0...1, reaching 1 when the image has fully left the top. The screen feeds it to an
///   `ILHeaderBlurView` in its sticky header band, so only a header-height strip blurs.
///
/// Z-order, bottom to top: `backgroundView` (clipped decoration, e.g. gradient / glow) → `imageView`
/// → `contentView` (overlay + text). Subclasses build their hero in the two slots. The view does not clip, so the scaled
/// image can grow above its frame; the screen's scroll view clips it.
///
/// The screen's nav bar sits outside this view — use `ILNavBar.usesTransparentButtons` for the
/// transparent header buttons.
class ILStretchyHeaderView: UIView {

    private enum Layout {
        /// Blur starts once the content scrolled past this fraction of `imageHeight`.
        static let blurStartFraction: CGFloat = 0.5
    }

    // MARK: - Slots
    /// Below the image, clipped to the header bounds.
    let backgroundView = UIView()
    /// Image pinned to the top of the header; its height is `imageHeight`.
    let imageView = ILRemoteImageView(frame: .zero)
    /// Above the image.
    let contentView = UIView()

    /// Height of the image area. `0` means "no image": nothing stretches and the header never blurs.
    var imageHeight: CGFloat = 0 {
        didSet {
            guard imageHeight != oldValue else { return }
            imageHeightConstraint.constant = imageHeight
            update(contentOffsetY: lastContentOffsetY)
        }
    }

    /// Blur progress 0...1 for the screen's header blur strip; called on every `update`.
    var onBlurProgress: ((CGFloat) -> Void)?

    // MARK: - Private
    private var lastContentOffsetY: CGFloat = 0
    private lazy var imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: imageHeight)

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHeaderViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public
    /// Call from `scrollViewDidScroll` with `scrollView.contentOffset.y` (the scroll view must
    /// have `contentInsetAdjustmentBehavior = .never` and the header at the top of its content).
    func update(contentOffsetY offsetY: CGFloat) {
        lastContentOffsetY = offsetY
        guard imageHeight > 0 else {
            imageView.transform = .identity
            onBlurProgress?(0)
            return
        }
        updateImageTransform(stretch: max(0, -offsetY))
        updateBlur(offsetY: offsetY)
    }

    // MARK: - Setup
    private func setupHeaderViews() {
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = false

        backgroundView.clipsToBounds = true
        imageView.isAccessibilityElement = false

        [backgroundView, imageView, contentView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),

            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageHeightConstraint,

            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Stretch
    /// Scales the image up from its top edge so the top stays on the screen top while the bottom
    /// follows the content (`stretch` = how far the content was pulled down).
    private func updateImageTransform(stretch: CGFloat) {
        guard stretch > 0 else {
            imageView.transform = .identity
            return
        }
        let scale = (imageHeight + stretch) / imageHeight
        // Scaling about the centre moves the top up by `stretch / 2`; shift back up by the same
        // amount so the top edge sits exactly `stretch` above the header (on the screen top).
        imageView.transform = CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: 0, y: -stretch / (2 * scale))
    }

    // MARK: - Blur
    private func updateBlur(offsetY: CGFloat) {
        let start = imageHeight * Layout.blurStartFraction
        onBlurProgress?(min(max((offsetY - start) / (imageHeight - start), 0), 1))
    }
}
