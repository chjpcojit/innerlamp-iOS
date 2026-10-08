//
//  ILHeaderBlurView.swift
//  InnerLamp
//

import UIKit

/// Blur strip for a sticky header band: the content scrolling underneath gets blurrier as
/// `progress` goes from 0 (no blur) to 1 (`maxIntensity`). Driven by `ILStretchyHeaderView.onBlurProgress`.
final class ILHeaderBlurView: UIVisualEffectView {

    private var animator: UIViewPropertyAnimator?
    private var progress: CGFloat = 0
    private var foregroundObserver: NSObjectProtocol?

    init() {
        super.init(effect: nil)
        isUserInteractionEnabled = false
        isHidden = true
        // A paused animator is reset by the system while the app is in the background; rebuild it.
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.restoreAfterForeground() }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let foregroundObserver { NotificationCenter.default.removeObserver(foregroundObserver) }
        finishAnimator()
    }

    func setProgress(_ newProgress: CGFloat) {
        progress = min(max(newProgress, 0), 1)
        isHidden = progress <= 0
        guard progress > 0 else { return }
        if animator == nil { animator = makeAnimator() }
        animator?.fractionComplete = progress * ILMetrics.headerBlurMaxIntensity
    }

    /// A paused animator whose `fractionComplete` drives the blur radius (the only way to get a
    /// partial `UIBlurEffect`).
    private func makeAnimator() -> UIViewPropertyAnimator {
        effect = nil
        let animator = UIViewPropertyAnimator(duration: 1, curve: .linear) { [weak self] in
            self?.effect = UIBlurEffect(style: .systemUltraThinMaterial)
        }
        animator.pausesOnCompletion = true
        return animator
    }

    private func restoreAfterForeground() {
        finishAnimator()
        setProgress(progress)
    }

    /// A `UIViewPropertyAnimator` must be inactive when it is released, otherwise UIKit asserts.
    private func finishAnimator() {
        guard let animator else { return }
        self.animator = nil
        if animator.state == .active { animator.stopAnimation(false) }
        if animator.state == .stopped { animator.finishAnimation(at: .current) }
    }
}
