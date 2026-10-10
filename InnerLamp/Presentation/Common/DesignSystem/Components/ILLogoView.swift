//
//  ILLogoView.swift
//  InnerLamp
//

import UIKit

/// Logo InnerLamp (`IL-Logo` của design handoff): vòng viền vàng dày + vầng sáng + ngọn lửa hai lớp.
///
/// Mọi tỉ lệ suy ra từ `size` theo đúng công thức của `IL-Logo.dc.html`:
/// viền `size × 1.5/32`, ngọn lửa rộng `size × 0.31` (tỉ lệ viewBox 40 : 56), chân lửa cách đáy
/// phần trong của vòng `size × 0.22`. Vì vậy dùng được từ 32 (top bar) tới 100 (hero Đăng ký).
///
/// Ngọn lửa dựng bằng `CAShapeLayer` từ path SVG của design (không dùng ảnh) nên giữ nét ở mọi
/// kích thước. Màn Splash có thể chạy thêm `startIgniteAnimation`/`startFlickerAnimation`.
public final class ILLogoView: UIView {

    // MARK: - Spec
    private enum Ratio {
        static let borderWidth: CGFloat = 1.5 / 32.0
        static let flameWidth: CGFloat = 0.31
        static let flameBottomInset: CGFloat = 0.22
        /// `radial-gradient(circle at 50% 74%, …, transparent 62%)`
        static let glowCenterY: CGFloat = 0.74
        static let glowStop: CGFloat = 0.62
    }

    /// viewBox của path SVG ngọn lửa.
    private static let flameViewBox = CGSize(width: 40, height: 56)

    // MARK: - Layers
    private let glowLayer = CAGradientLayer()
    /// Container neo ở đáy giữa — `transform-origin: 50% 100%` của `ilignite`.
    private let flameBodyLayer = CALayer()
    private let flameOuterLayer = CAShapeLayer()
    private let flameCoreLayer = CAShapeLayer()

    // MARK: - Properties
    public let size: CGFloat
    private var borderWidth: CGFloat { size * Ratio.borderWidth }
    private var flameSize: CGSize {
        let width = size * Ratio.flameWidth
        return CGSize(width: width, height: width * Self.flameViewBox.height / Self.flameViewBox.width)
    }

    // MARK: - Initializer
    public init(size: CGFloat) {
        self.size = size
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
        backgroundColor = .clear

        layer.cornerRadius = size / 2.0
        layer.borderWidth = borderWidth

        glowLayer.type = .radial
        glowLayer.locations = [0.0, 1.0]
        glowLayer.startPoint = CGPoint(x: 0.5, y: Ratio.glowCenterY)
        // Bán kính vầng = 62% khoảng cách tới góc xa nhất (≈ 0.893 × size) → 0.554 × size.
        let radius = Ratio.glowStop * hypot(0.5, Ratio.glowCenterY)
        glowLayer.endPoint = CGPoint(x: 0.5 + radius, y: Ratio.glowCenterY + radius)
        layer.addSublayer(glowLayer)

        flameBodyLayer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        layer.addSublayer(flameBodyLayer)

        flameOuterLayer.path = Self.outerFlamePath.cgPath
        flameCoreLayer.path = Self.coreFlamePath.cgPath
        flameBodyLayer.addSublayer(flameOuterLayer)
        flameBodyLayer.addSublayer(flameCoreLayer)

        updateColors()

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: size),
            heightAnchor.constraint(equalToConstant: size)
        ])

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILLogoView, _) in
            view.updateColors()
        }
    }

    /// `CGColor` không tự đảo theo trait — resolve lại theo appearance hiện tại.
    private func updateColors() {
        layer.borderColor = ILColors.logoRing.resolvedColor(with: traitCollection).cgColor
        glowLayer.colors = [
            ILColors.goldBright.withAlphaComponent(0.22).resolvedColor(with: traitCollection).cgColor,
            ILColors.goldGlowClear.resolvedColor(with: traitCollection).cgColor
        ]
        flameOuterLayer.fillColor = ILColors.logoFlame.resolvedColor(with: traitCollection).cgColor
        flameCoreLayer.fillColor = ILColors.logoFlameCore.resolvedColor(with: traitCollection).cgColor
        // `drop-shadow(0 0 fw×0.15 rgba(217,150,60,.8))`
        flameOuterLayer.shadowColor = ILColors.goldBright.resolvedColor(with: traitCollection).cgColor
    }

    // MARK: - Layout
    public override var intrinsicContentSize: CGSize {
        CGSize(width: size, height: size)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        glowLayer.frame = bounds.insetBy(dx: borderWidth, dy: borderWidth)
        // Gradient được tính theo bounds của `glowLayer` (đã trừ viền) nên bù tỉ lệ cho đúng
        // tâm 50% / 74% của padding box.
        glowLayer.cornerRadius = glowLayer.bounds.width / 2.0

        let flame = flameSize
        let flameBottom = bounds.maxY - borderWidth - size * Ratio.flameBottomInset
        flameBodyLayer.bounds = CGRect(origin: .zero, size: flame)
        flameBodyLayer.position = CGPoint(x: bounds.midX, y: flameBottom)

        let scale = CGAffineTransform(
            scaleX: flame.width / Self.flameViewBox.width,
            y: flame.height / Self.flameViewBox.height
        )
        // Path nằm trong hệ toạ độ viewBox → bounds của shape = viewBox, rồi scale về cỡ thật.
        for shape in [flameOuterLayer, flameCoreLayer] {
            shape.bounds = CGRect(origin: .zero, size: Self.flameViewBox)
            shape.anchorPoint = .zero
            shape.position = .zero
            shape.setAffineTransform(scale)
        }
        flameOuterLayer.shadowRadius = flame.width * 0.15 / 2.0 / scale.a
        flameOuterLayer.shadowOpacity = 0.8
        flameOuterLayer.shadowOffset = .zero
        flameOuterLayer.shadowPath = Self.outerFlamePath.cgPath

        CATransaction.commit()
    }

    // MARK: - Paths (SVG của IL-Logo, viewBox 40 × 56)
    private static let outerFlamePath: UIBezierPath = {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 23, y: 1))
        path.addCurve(to: CGPoint(x: 36, y: 34), controlPoint1: CGPoint(x: 25, y: 11), controlPoint2: CGPoint(x: 36, y: 19))
        path.addCurve(to: CGPoint(x: 20, y: 54), controlPoint1: CGPoint(x: 36, y: 46), controlPoint2: CGPoint(x: 28, y: 54))
        path.addCurve(to: CGPoint(x: 4, y: 37), controlPoint1: CGPoint(x: 12, y: 54), controlPoint2: CGPoint(x: 4, y: 47))
        path.addCurve(to: CGPoint(x: 13, y: 16), controlPoint1: CGPoint(x: 4, y: 28), controlPoint2: CGPoint(x: 10, y: 23))
        path.addCurve(to: CGPoint(x: 21, y: 27), controlPoint1: CGPoint(x: 15, y: 23), controlPoint2: CGPoint(x: 18, y: 26))
        path.addCurve(to: CGPoint(x: 23, y: 1), controlPoint1: CGPoint(x: 19, y: 18), controlPoint2: CGPoint(x: 19, y: 10))
        path.close()
        return path
    }()

    private static let coreFlamePath: UIBezierPath = {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 21, y: 30))
        path.addCurve(to: CGPoint(x: 26, y: 42), controlPoint1: CGPoint(x: 23, y: 35), controlPoint2: CGPoint(x: 26, y: 38))
        // `a6 6 0 0 1 -12 0` — nửa vòng phía dưới, từ (26,42) sang (14,42).
        path.addArc(withCenter: CGPoint(x: 20, y: 42), radius: 6, startAngle: 0, endAngle: .pi, clockwise: true)
        path.addCurve(to: CGPoint(x: 17, y: 34), controlPoint1: CGPoint(x: 14, y: 39), controlPoint2: CGPoint(x: 16, y: 37))
        path.addCurve(to: CGPoint(x: 20, y: 37), controlPoint1: CGPoint(x: 18, y: 36), controlPoint2: CGPoint(x: 19, y: 37))
        path.addCurve(to: CGPoint(x: 21, y: 30), controlPoint1: CGPoint(x: 19, y: 35), controlPoint2: CGPoint(x: 19, y: 33))
        path.close()
        return path
    }()

    // MARK: - Animations
    // CAAnimation add trước khi view có window sẽ bị Core Animation bỏ qua — chỉ gọi sau khi
    // view đã lên màn (vd. trong `viewDidAppear`), không phải lúc khởi tạo.

    /// `ilrise` (cả vòng trồi lên) + `ilignite` (lửa bùng) — cùng API với `ILLampGlowView`.
    public func startIgniteAnimation(delay: TimeInterval = 0, flameDelay: TimeInterval? = nil) {
        let riseBegin = CACurrentMediaTime() + delay

        let rise = CABasicAnimation(keyPath: "transform.translation.y")
        rise.fromValue = 10.0
        rise.toValue = 0.0
        rise.duration = Self.riseDuration
        rise.beginTime = riseBegin
        rise.timingFunction = CAMediaTimingFunction(name: .easeOut)
        rise.fillMode = .backwards
        layer.add(rise, forKey: "ilLogoRise")

        let riseOpacity = CABasicAnimation(keyPath: "opacity")
        riseOpacity.fromValue = 0.0
        riseOpacity.toValue = 1.0
        riseOpacity.duration = Self.riseDuration
        riseOpacity.beginTime = riseBegin
        riseOpacity.timingFunction = CAMediaTimingFunction(name: .easeOut)
        riseOpacity.fillMode = .backwards
        layer.add(riseOpacity, forKey: "ilLogoRiseOpacity")

        let igniteBegin = CACurrentMediaTime() + (flameDelay ?? delay)

        let ignite = CAKeyframeAnimation(keyPath: "transform.scale")
        ignite.values = [0.0, 1.22, 0.92, 1.0]
        ignite.keyTimes = [0.0, 0.42, 0.70, 1.0]
        ignite.duration = Self.igniteDuration
        ignite.beginTime = igniteBegin
        ignite.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.9, 0.3, 1.0)
        ignite.fillMode = .backwards
        flameBodyLayer.add(ignite, forKey: "ilLogoIgnite")

        let igniteOpacity = CAKeyframeAnimation(keyPath: "opacity")
        igniteOpacity.values = [0.0, 1.0, 1.0]
        igniteOpacity.keyTimes = [0.0, 0.42, 1.0]
        igniteOpacity.duration = Self.igniteDuration
        igniteOpacity.beginTime = igniteBegin
        igniteOpacity.fillMode = .backwards
        flameBodyLayer.add(igniteOpacity, forKey: "ilLogoIgniteOpacity")
    }

    /// `ilpulse` — nhịp thở nhẹ của ngọn lửa sau khi bùng.
    public func startFlickerAnimation(delay: TimeInterval = 0) {
        let pulse = CAKeyframeAnimation(keyPath: "opacity")
        pulse.values = [0.55, 0.95, 0.55]
        pulse.keyTimes = [0, 0.5, 1]
        pulse.duration = 2.6
        pulse.beginTime = CACurrentMediaTime() + delay
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        flameBodyLayer.add(pulse, forKey: "ilLogoPulse")
    }

    private static let riseDuration: TimeInterval = 0.7
    private static let igniteDuration: TimeInterval = 1.1
}
