//
//  ILSkeletonBarView.swift
//  InnerLamp
//

import UIKit

/// One pulsing placeholder block (rounded rect) for section-level loading states — compose several
/// into a card-shaped skeleton. For a whole-screen first load use `ILSkeletonLoadingView` instead.
///
/// Pulses (`ilpulse`, same timing tokens as `ILSkeletonLoadingView`) while it is in a window and
/// settles on a static opacity when Reduce Motion is on.
public final class ILSkeletonBarView: UIView {

    // MARK: - Properties
    private let pulseDelay: TimeInterval

    // MARK: - Initializer
    public init(
        color: UIColor = ILColors.Skeleton.bar,
        cornerRadius: CGFloat = ILMetrics.Skeleton.rowLineRadius,
        pulseDelay: TimeInterval = 0
    ) {
        self.pulseDelay = pulseDelay
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = color
        layer.cornerRadius = cornerRadius
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        // CAAnimations added before the view has a window are dropped by Core Animation.
        if window != nil { startPulsing() } else { stopPulsing() }
    }

    // MARK: - Animation
    private func startPulsing() {
        stopPulsing()

        guard !UIAccessibility.isReduceMotionEnabled else {
            layer.opacity = ILMetrics.Skeleton.pulseStaticOpacity
            return
        }

        let pulse = CAKeyframeAnimation(keyPath: "opacity")
        pulse.values = [
            ILMetrics.Skeleton.pulseMinOpacity,
            ILMetrics.Skeleton.pulseMaxOpacity,
            ILMetrics.Skeleton.pulseMinOpacity
        ]
        pulse.keyTimes = [0, 0.5, 1]
        pulse.duration = ILMetrics.Skeleton.pulseDuration
        pulse.repeatCount = .infinity
        pulse.beginTime = CACurrentMediaTime() + pulseDelay
        pulse.fillMode = .backwards
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        // Keeps the pulse alive across app background/foreground.
        pulse.isRemovedOnCompletion = false
        layer.add(pulse, forKey: Self.pulseAnimationKey)
    }

    private func stopPulsing() {
        layer.removeAnimation(forKey: Self.pulseAnimationKey)
        layer.opacity = 1
    }

    private static let pulseAnimationKey = "ilSkeletonBarPulse"
}
