//
//  ILSplashAmbienceView.swift
//  InnerLamp
//

import UIKit

/// Hiệu ứng nền chuyển động của màn Splash: ba vòng ripple lan ra từ tâm đèn và hai tia sáng
/// quét chéo qua đỉnh. Đây là lớp **dưới** vòng đèn — design xếp chúng trước khối đèn nên đèn
/// luôn nằm trên.
///
/// Hạt than hồng không nằm ở đây: chúng ở trong lòng vòng đèn nên phải vẽ **trên** nó, tách
/// sang `ILSplashEmberFieldView`.
///
/// Kích thước/toạ độ/duration lấy nguyên từ design handoff (`isSplash`) — bố cục Splash dựng
/// quanh vòng đèn 96pt cố định, không co giãn theo screen size.
final class ILSplashAmbienceView: UIView {

    // MARK: - Spec
    private enum Metrics {
        static let rippleDiameter: CGFloat = 300
        /// Tâm vòng ripple ở 42% chiều cao màn (`top:42%` cộng `translate(-50%,-50%)` của design).
        static let rippleCenterYRatio: CGFloat = 0.42
        static let raySize = CGSize(width: 2, height: 190)
        /// Đỉnh tia sáng ở 16% chiều cao màn (`top:16%`).
        static let rayTopRatio: CGFloat = 0.16
    }

    private enum Timing {
        static let rippleDuration: TimeInterval = 3.4
        /// Ba vòng phát lệch nhau 1.1s (`animation-delay` 0 / 1.1s / 2.2s).
        static let rippleDelayStep: TimeInterval = 1.1
        static let rayDuration: TimeInterval = 2.6
        static let rayDelay: TimeInterval = 0.3
    }

    /// Ba vòng ripple nhạt dần theo thứ tự phát (`--il-spl-ring` → `-ring3`).
    private static let rippleColors: [UIColor] = [
        ILColors.splashRing,
        ILColors.splashRing2,
        ILColors.splashRing3
    ]

    // MARK: - UI Elements
    private let rippleViews: [UIView]
    private let rayViews: [RayView]

    // MARK: - Initializer
    init() {
        rippleViews = Self.rippleColors.map { color in
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.isUserInteractionEnabled = false
            view.backgroundColor = .clear
            view.layer.borderWidth = 1
            view.layer.borderColor = color.cgColor
            view.layer.cornerRadius = Metrics.rippleDiameter / 2.0
            return view
        }

        rayViews = [
            RayView(color: ILColors.splashRay),
            RayView(color: ILColors.splashRay2)
        ]

        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        // Cả view chỉ để vẽ — không được chặn touch của màn.
        isUserInteractionEnabled = false
        backgroundColor = .clear

        rippleViews.forEach { ripple in
            addSubview(ripple)
            NSLayoutConstraint.activate([
                ripple.widthAnchor.constraint(equalToConstant: Metrics.rippleDiameter),
                ripple.heightAnchor.constraint(equalToConstant: Metrics.rippleDiameter),
                ripple.centerXAnchor.constraint(equalTo: centerXAnchor),
                // Neo vào `.bottom` của chính view để ra được vị trí theo tỉ lệ chiều cao màn.
                NSLayoutConstraint(
                    item: ripple, attribute: .centerY, relatedBy: .equal,
                    toItem: self, attribute: .bottom,
                    multiplier: Metrics.rippleCenterYRatio, constant: 0
                )
            ])
        }

        rayViews.forEach { ray in
            addSubview(ray)
            NSLayoutConstraint.activate([
                ray.widthAnchor.constraint(equalToConstant: Metrics.raySize.width),
                ray.heightAnchor.constraint(equalToConstant: Metrics.raySize.height),
                ray.centerXAnchor.constraint(equalTo: centerXAnchor),
                NSLayoutConstraint(
                    item: ray, attribute: .top, relatedBy: .equal,
                    toItem: self, attribute: .bottom,
                    multiplier: Metrics.rayTopRatio, constant: 0
                )
            ])
        }
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILSplashAmbienceView, _) in
            view.applyColorAppearanceChange()
        }
    }

    // MARK: - Animations
    // CAAnimation add trước khi view có window sẽ bị Core Animation bỏ qua — chỉ gọi sau khi
    // view đã lên màn (vd. trong `viewDidAppear`), không phải lúc khởi tạo.

    private func applyColorAppearanceChange() {
        updateColors()
    }

    /// Viền ripple (`layer.borderColor`) và gradient tia sáng không tự đảo theo trait —
    /// resolve lại thủ công theo appearance hiện tại.
    private func updateColors() {
        for (index, ripple) in rippleViews.enumerated() {
            ripple.layer.borderColor = Self.rippleColors[index]
                .resolvedColor(with: traitCollection).cgColor
        }
        rayViews.forEach { $0.updateColors(with: traitCollection) }
    }

    /// Cả hai nhóm hiệu ứng nền — ViewController chỉ cần gọi một lần.
    func startAnimations() {
        startRippleAnimation()
        startRayAnimation()
    }

    /// `ilripple`: vòng lan từ 0.34 lên 2.5 lần kích thước gốc, mờ dần rồi tắt hẳn.
    private func startRippleAnimation() {
        let timing = CAMediaTimingFunction(controlPoints: 0.22, 0.7, 0.3, 1.0)

        for (index, ripple) in rippleViews.enumerated() {
            let beginTime = CACurrentMediaTime() + Double(index) * Timing.rippleDelayStep

            let scale = CAKeyframeAnimation(keyPath: "transform.scale")
            scale.values = [0.34, 2.5]
            scale.keyTimes = [0.0, 1.0]
            scale.duration = Timing.rippleDuration
            scale.beginTime = beginTime
            scale.repeatCount = .infinity
            scale.timingFunction = timing
            ripple.layer.add(scale, forKey: "ilRippleScale")

            // Đỉnh độ sáng ở 14% thời lượng rồi tắt dần hết vòng đời.
            let opacity = CAKeyframeAnimation(keyPath: "opacity")
            opacity.values = [0.0, 0.55, 0.0]
            opacity.keyTimes = [0.0, 0.14, 1.0]
            opacity.duration = Timing.rippleDuration
            opacity.beginTime = beginTime
            opacity.repeatCount = .infinity
            opacity.timingFunction = timing
            ripple.layer.add(opacity, forKey: "ilRippleOpacity")
        }
    }

    /// `ilray`: mỗi tia quét **một lần** rồi nằm im ở trạng thái trong suốt — tia thứ hai của
    /// design chạy `reverse` nên giá trị keyframe đảo chiều.
    private func startRayAnimation() {
        let beginTime = CACurrentMediaTime() + Timing.rayDelay
        let maxAngle = 28.0 * .pi / 180.0

        for (index, ray) in rayViews.enumerated() {
            let isReversed = index == 1

            let opacity = CAKeyframeAnimation(keyPath: "opacity")
            opacity.values = [0.0, 0.5, 0.0]
            // Chạy xuôi: sáng nhất ở 30%. Chạy ngược: sáng nhất ở 70%.
            opacity.keyTimes = isReversed ? [0.0, 0.7, 1.0] : [0.0, 0.3, 1.0]
            opacity.duration = Timing.rayDuration
            opacity.beginTime = beginTime
            opacity.timingFunction = CAMediaTimingFunction(name: .easeOut)
            // Giữ nguyên trạng thái cuối (trong suốt) thay vì bật lại tia sáng khi animation gỡ.
            opacity.fillMode = .both
            opacity.isRemovedOnCompletion = false
            ray.gradientLayer.add(opacity, forKey: "ilRayOpacity")

            let rotation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
            rotation.values = isReversed ? [maxAngle, 0.0] : [0.0, maxAngle]
            rotation.keyTimes = [0.0, 1.0]
            rotation.duration = Timing.rayDuration
            rotation.beginTime = beginTime
            rotation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            rotation.fillMode = .both
            rotation.isRemovedOnCompletion = false
            ray.gradientLayer.add(rotation, forKey: "ilRayRotation")

            let stretch = CAKeyframeAnimation(keyPath: "transform.scale.y")
            stretch.values = isReversed ? [1.0, 0.4] : [0.4, 1.0]
            stretch.keyTimes = [0.0, 1.0]
            stretch.duration = Timing.rayDuration
            stretch.beginTime = beginTime
            stretch.timingFunction = CAMediaTimingFunction(name: .easeOut)
            stretch.fillMode = .both
            stretch.isRemovedOnCompletion = false
            ray.gradientLayer.add(stretch, forKey: "ilRayStretch")
        }
    }
}

// MARK: - Ray
/// Thanh gradient mảnh quay quanh **đáy** của nó (`transform-origin: 50% 100%` của design).
///
/// Không đặt `anchorPoint` lên layer của view đang có constraint (sẽ đẩy lệch view) — thay vào
/// đó view chỉ là khung định vị, còn thanh gradient là sublayer neo đáy bên trong.
private final class RayView: UIView {

    let gradientLayer = CAGradientLayer()
    private let color: UIColor

    init(color: UIColor) {
        self.color = color
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = false
        backgroundColor = .clear

        gradientLayer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        layer.addSublayer(gradientLayer)
        updateColors(with: traitCollection)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// `transparent → màu → transparent`: hai đầu mờ hẳn cùng sắc độ để không bị xám ở mép.
    /// Gọi lại khi theme đổi vì `CAGradientLayer.colors` không tự đảo theo trait.
    func updateColors(with traitCollection: UITraitCollection) {
        let resolved = color.resolvedColor(with: traitCollection)
        gradientLayer.colors = [
            resolved.withAlphaComponent(0.0).cgColor,
            resolved.cgColor,
            resolved.withAlphaComponent(0.0).cgColor
        ]
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        // `position` là tâm theo `anchorPoint` = đáy giữa, nên thanh phủ kín khung view.
        gradientLayer.bounds = CGRect(origin: .zero, size: bounds.size)
        gradientLayer.position = CGPoint(x: bounds.midX, y: bounds.maxY)
        CATransaction.commit()
    }
}
