//
//  ILEntranceAnimator.swift
//  InnerLamp
//

import UIKit

/// Shared first-open entrance effect: every target fades in while sliding up to its rest position.
///
/// The slide distance grows with the target's index (`minOffset` → `maxOffset`) and each target
/// starts a little later (`stagger`), so lower layers travel further and land last — a cheap
/// depth/parallax feel. Screens do not call this directly: override
/// `BaseViewController.entranceAnimationTargets()` and the base class runs it once on first appear.
/// Skipped entirely when Reduce Motion is on.
enum ILEntranceAnimator {

    static let minOffset: CGFloat = 20
    static let maxOffset: CGFloat = 40
    static let duration: TimeInterval = 0.7
    static let stagger: TimeInterval = 0.08

    /// Moves the targets to their start pose (transparent, shifted down) before the screen shows.
    static func prepare(_ targets: [UIView]) {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        for (index, view) in targets.enumerated() {
            view.alpha = 0
            view.transform = CGAffineTransform(translationX: 0, y: offset(at: index, of: targets.count))
        }
    }

    /// Animates the targets from the `prepare` pose back to rest.
    static func play(_ targets: [UIView]) {
        guard !UIAccessibility.isReduceMotionEnabled else {
            targets.forEach { rest($0) }
            return
        }
        for (index, view) in targets.enumerated() {
            UIView.animate(
                withDuration: duration,
                delay: stagger * Double(index),
                options: [.curveEaseOut, .allowUserInteraction, .beginFromCurrentState]
            ) {
                rest(view)
            }
        }
    }

    private static func rest(_ view: UIView) {
        view.alpha = 1
        view.transform = .identity
    }

    private static func offset(at index: Int, of count: Int) -> CGFloat {
        guard count > 1 else { return minOffset }
        let progress = CGFloat(index) / CGFloat(count - 1)
        return minOffset + (maxOffset - minOffset) * progress
    }
}
