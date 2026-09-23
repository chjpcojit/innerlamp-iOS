//
//  ILSplashBrandBackdropView.swift
//  InnerLamp
//

import UIKit

/// Nền màn Splash: radial tối `#2A241C → #100E0B` cộng một quầng sáng vàng phía trên.
///
/// Màn Splash **luôn tối** theo design handoff (nằm trong nhóm màn không đi qua token `--il-*`
/// theo theme), nên nền ở đây lấy thẳng cặp `darkBackgroundTop`/`darkBackground` và **không**
/// đảo màu theo light/dark — khác các màn dùng `canvasWarm` như Login/Onboarding.
final class ILSplashBrandBackdropView: UIView {

    // MARK: - Spec
    private enum Metrics {
        /// Tâm vòng sáng ở 42% chiều cao màn (`circle at 50% 42%` của design).
        static let gradientCenterYRatio: CGFloat = 0.42
        /// Điểm dừng màu kết thúc của radial nền (`#100E0B 72%`).
        static let gradientEndLocation: NSNumber = 0.72

        static let glowSize: CGFloat = 420
        /// Mép trên quầng sáng ở 26% chiều cao màn (`top:26%` của design).
        static let glowTopRatio: CGFloat = 0.26
        /// Quầng tắt dần ở 62% bán kính.
        static let glowEndLocation: NSNumber = 0.62
    }

    private enum Timing {
        /// `ilglow 3.4s ease-in-out infinite`.
        static let glowDuration: TimeInterval = 3.4
        static let glowMinOpacity: Float = 0.5
        static let glowMaxOpacity: Float = 1.0
        static let glowMinScale: CGFloat = 0.96
        static let glowMaxScale: CGFloat = 1.06
    }

    // MARK: - Layers
    private let backgroundGradientLayer = CAGradientLayer()
    private let topGlowView = UIView()
    private let topGlowGradientLayer = CAGradientLayer()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = false

        // radial-gradient(circle at 50% 42%, #2A241C, #100E0B 72%)
        backgroundGradientLayer.type = .radial
        backgroundGradientLayer.colors = [
            ILColors.darkBackgroundTop.cgColor,
            ILColors.darkBackground.cgColor
        ]
        backgroundGradientLayer.locations = [0.0, Metrics.gradientEndLocation]
        backgroundGradientLayer.startPoint = CGPoint(x: 0.5, y: Metrics.gradientCenterYRatio)
        backgroundGradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        layer.insertSublayer(backgroundGradientLayer, at: 0)

        // radial-gradient(circle, rgba(217,150,60,.26), transparent 62%)
        topGlowView.translatesAutoresizingMaskIntoConstraints = false
        topGlowView.isUserInteractionEnabled = false
        topGlowView.backgroundColor = .clear
        topGlowGradientLayer.type = .radial
        topGlowGradientLayer.colors = [
            ILColors.goldGlowStrong.cgColor,
            ILColors.goldGlowClear.cgColor
        ]
        topGlowGradientLayer.locations = [0.0, Metrics.glowEndLocation]
        topGlowGradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        topGlowGradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        topGlowView.layer.addSublayer(topGlowGradientLayer)
        addSubview(topGlowView)

        NSLayoutConstraint.activate([
            topGlowView.centerXAnchor.constraint(equalTo: centerXAnchor),
            // Neo vào `.bottom` để ra được vị trí theo tỉ lệ chiều cao màn.
            NSLayoutConstraint(
                item: topGlowView, attribute: .top, relatedBy: .equal,
                toItem: self, attribute: .bottom,
                multiplier: Metrics.glowTopRatio, constant: 0
            ),
            topGlowView.widthAnchor.constraint(equalToConstant: Metrics.glowSize),
            topGlowView.heightAnchor.constraint(equalToConstant: Metrics.glowSize)
        ])
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        backgroundGradientLayer.frame = bounds
        topGlowGradientLayer.frame = topGlowView.bounds
        CATransaction.commit()
    }

    // MARK: - Animations
    // CAAnimation add trước khi view có window sẽ bị Core Animation bỏ qua — chỉ gọi sau khi
    // view đã lên màn (vd. trong `viewDidAppear`), không phải lúc khởi tạo.

    /// `ilglow 3.4s ease-in-out infinite` — quầng sáng thở nhẹ, sáng dần rồi tối lại.
    func startGlowAnimation() {
        let opacity = CAKeyframeAnimation(keyPath: "opacity")
        opacity.values = [Timing.glowMinOpacity, Timing.glowMaxOpacity, Timing.glowMinOpacity]
        opacity.keyTimes = [0, 0.5, 1]
        opacity.duration = Timing.glowDuration
        opacity.repeatCount = .infinity
        opacity.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        topGlowView.layer.add(opacity, forKey: "ilGlowOpacity")

        // `scale(.96) → scale(1.06)` — mặc định `anchorPoint` của view đã ở tâm nên scale
        // đúng quanh tâm quầng, không cần sublayer neo riêng.
        let scale = CAKeyframeAnimation(keyPath: "transform.scale")
        scale.values = [Timing.glowMinScale, Timing.glowMaxScale, Timing.glowMinScale]
        scale.keyTimes = [0, 0.5, 1]
        scale.duration = Timing.glowDuration
        scale.repeatCount = .infinity
        scale.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        topGlowView.layer.add(scale, forKey: "ilGlowScale")
    }
}
