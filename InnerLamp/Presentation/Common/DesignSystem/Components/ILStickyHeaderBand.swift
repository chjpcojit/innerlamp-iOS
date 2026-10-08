//
//  ILStickyHeaderBand.swift
//  InnerLamp
//

import UIKit

/// Glass band behind a sticky screen header (usually an `ILNavBar`): a blur strip plus a canvas tint
/// that go from "flat" to "glass" as the content scrolls under the band.
///
/// The band owns the blur + tint layers and pins them to its edges, behind whatever the screen adds
/// with `addSubview` afterwards (nav bar, divider...). It knows nothing about hero images, so it works
/// for plain screens and image-hero screens alike; only the source of `progress` differs:
/// - **Plain screens**: `bind(to:)` observes the scroll view and derives progress from how far the
///   content has scrolled under the band (`ILMetrics.headerBlurFadeDistance`).
/// - **Hero screens**: feed `setProgress(_:)` from `ILStretchyHeaderView.onBlurProgress` (or any custom curve).
///
/// Strength lives in `ILMetrics.headerBlurMaxIntensity` / `ILMetrics.headerGlassTintAlpha`, so tuning
/// the look of every header is a one-place change.
final class ILStickyHeaderBand: UIView {

    private let blurView = ILHeaderBlurView()
    private let tintView = UIView()
    private let tintRestAlpha: CGFloat
    private let tintGlassAlpha: CGFloat
    private var scrollObservations: [NSKeyValueObservation] = []

    /// - Parameters:
    ///   - tintColor: tint colour (usually the screen's canvas colour).
    ///   - tintRestAlpha: tint opacity at progress 0. `1` = opaque canvas (header looks flat), `0` = see-through.
    ///   - tintGlassAlpha: tint opacity at progress 1.
    init(
        tintColor: UIColor = ILColors.canvas,
        tintRestAlpha: CGFloat = 1,
        tintGlassAlpha: CGFloat = ILMetrics.headerGlassTintAlpha
    ) {
        self.tintRestAlpha = tintRestAlpha
        self.tintGlassAlpha = tintGlassAlpha
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        tintView.backgroundColor = tintColor
        tintView.isUserInteractionEnabled = false
        [blurView, tintView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
            NSLayoutConstraint.activate([
                $0.topAnchor.constraint(equalTo: topAnchor),
                $0.leadingAnchor.constraint(equalTo: leadingAnchor),
                $0.trailingAnchor.constraint(equalTo: trailingAnchor),
                $0.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }
        setProgress(0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// `0` = flat header, `1` = full glass (blur at `headerBlurMaxIntensity`, tint at `tintGlassAlpha`).
    func setProgress(_ progress: CGFloat) {
        let clamped = min(max(progress, 0), 1)
        blurView.setProgress(clamped)
        tintView.alpha = tintRestAlpha + (tintGlassAlpha - tintRestAlpha) * clamped
    }

    /// Drives the band from `scrollView`: progress is how far the content has scrolled past its top
    /// inset (so a scroll view whose `contentInset.top` equals the band height starts at 0).
    /// Replaces any previous binding.
    func bind(to scrollView: UIScrollView, fadeDistance: CGFloat = ILMetrics.headerBlurFadeDistance) {
        let refresh: (UIScrollView) -> Void = { [weak self] scrollView in
            let scrolled = scrollView.contentOffset.y + scrollView.contentInset.top
            self?.setProgress(scrolled / fadeDistance)
        }
        scrollObservations = [
            scrollView.observe(\.contentOffset, options: [.initial, .new]) { scrollView, _ in refresh(scrollView) },
            scrollView.observe(\.contentInset, options: [.new]) { scrollView, _ in refresh(scrollView) }
        ]
    }
}
