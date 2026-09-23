//
//  ILFlameView.swift
//  InnerLamp
//

import UIKit

/// Ngọn lửa đơn lẻ — hình giọt nước dựng bằng `CAShapeLayer` với gradient dọc
/// (kem sáng ở đỉnh → vàng đậm ở chân) + quầng sáng loang ra ngoài.
///
/// Tách khỏi `ILLampGlowView` vì bản thân ngọn lửa là hình khối được tái sử dụng
/// (Splash, các màn hero tối) tách biệt với cái vòng bao quanh nó — vòng đó là
/// chi tiết của từng màn, còn ngọn lửa thì luôn giống nhau.
///
/// Không dùng Auto Layout bên trong: mọi thứ là sublayer của `bodyLayer`, được đặt
/// thủ công trong `layoutSubviews`. Cần vậy vì `bodyLayer.anchorPoint` phải nằm ở
/// đáy (`transform-origin: 50% 100%` của design — lửa bùng lên từ chân tim), mà
/// đổi `anchorPoint` trên layer của một view có constraint sẽ đẩy lệch cả view.
public final class ILFlameView: UIView {

    // MARK: - Layers
    /// Container bọc quầng sáng + thân lửa, anchor ở đáy để scale đúng gốc.
    private let bodyLayer = CALayer()
    private let glowLayer = CAGradientLayer()
    private let gradientLayer = CAGradientLayer()
    private let shapeLayer = CAShapeLayer()

    // MARK: - Properties
    /// Chiều cao ngọn lửa (pt). Chiều rộng suy ra theo tỉ lệ 14 : 20 của design.
    public let height: CGFloat
    private var width: CGFloat { height * 0.7 }

    /// Quầng sáng rộng gấp 4 lần thân lửa để loang mềm ra hai bên như `radial-gradient`.
    private var glowSize: CGSize { CGSize(width: width * 4.0, height: height * 3.2) }

    /// Sắc độ ở đỉnh ngọn lửa — chân lửa luôn là `goldBright`, chỉ đầu lửa đổi theo
    /// nền màn chứa nó (xem `ILLampGlowView.Style`).
    private let topColor: UIColor

    private var pendingIgniteCompletion: (() -> Void)?

    // MARK: - Initializer
    public init(height: CGFloat = 20, topColor: UIColor) {
        self.height = height
        self.topColor = topColor
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

        bodyLayer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        layer.addSublayer(bodyLayer)

        glowLayer.type = .radial
        glowLayer.colors = [
            ILColors.goldBright.withAlphaComponent(0.55).cgColor,
            ILColors.goldGlowClear.cgColor
        ]
        glowLayer.locations = [0.0, 1.0]
        glowLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        glowLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        bodyLayer.addSublayer(glowLayer)

        // Gradient dọc đầu sáng → vàng đậm, mask bằng hình giọt nước.
        gradientLayer.colors = [
            topColor.cgColor,
            ILColors.goldBright.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.mask = shapeLayer
        bodyLayer.addSublayer(gradientLayer)
    }

    // MARK: - Layout
    public override var intrinsicContentSize: CGSize {
        CGSize(width: width, height: height)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        // `bodyLayer.position` nằm ở đáy giữa view (do `anchorPoint` = đáy).
        bodyLayer.bounds = CGRect(origin: .zero, size: CGSize(width: width, height: height))
        bodyLayer.position = CGPoint(x: bounds.midX, y: bounds.maxY)

        gradientLayer.frame = bodyLayer.bounds
        shapeLayer.frame = gradientLayer.bounds
        shapeLayer.path = flamePath(in: shapeLayer.bounds).cgPath

        // Quầng sáng căn giữa thân lửa, tràn ra ngoài bounds — không clip.
        glowLayer.frame = CGRect(
            x: (width - glowSize.width) / 2.0,
            y: height - glowSize.height / 2.0 - height / 2.0,
            width: glowSize.width,
            height: glowSize.height
        )

        CATransaction.commit()
    }

    /// `border-radius: 50% 50% 46% 46% / 62% 62% 38% 38%` của design — bầu tròn ở
    /// trên, thuôn nhọn về chân.
    private func flamePath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let w = rect.width
        let h = rect.height

        let topRadius = w / 2.0
        let topVerticalRadius = h * 0.62
        let bottomRadius = w * 0.46
        let bottomVerticalRadius = h * 0.38

        path.move(to: CGPoint(x: rect.minX, y: rect.maxY - bottomVerticalRadius))

        // Cung dưới-trái: bán kính ngang 46%, dọc 38%.
        path.addCurve(
            to: CGPoint(x: rect.minX + bottomRadius, y: rect.maxY),
            controlPoint1: CGPoint(x: rect.minX, y: rect.maxY - bottomVerticalRadius * 0.45),
            controlPoint2: CGPoint(x: rect.minX + bottomRadius * 0.45, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - bottomRadius, y: rect.maxY))

        // Cung dưới-phải.
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY - bottomVerticalRadius),
            controlPoint1: CGPoint(x: rect.maxX - bottomRadius * 0.45, y: rect.maxY),
            controlPoint2: CGPoint(x: rect.maxX, y: rect.maxY - bottomVerticalRadius * 0.45)
        )

        // Hai bên thân lửa.
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + topVerticalRadius))

        // Cung trên-phải → đỉnh.
        path.addCurve(
            to: CGPoint(x: rect.maxX - topRadius, y: rect.minY),
            controlPoint1: CGPoint(x: rect.maxX, y: rect.minY + topVerticalRadius * 0.45),
            controlPoint2: CGPoint(x: rect.maxX - topRadius * 0.55, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.minX + topRadius, y: rect.minY))

        // Cung trên-trái → đóng về chân trái.
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.minY + topVerticalRadius),
            controlPoint1: CGPoint(x: rect.minX + topRadius * 0.55, y: rect.minY),
            controlPoint2: CGPoint(x: rect.minX, y: rect.minY + topVerticalRadius * 0.45)
        )
        path.close()
        return path
    }

    // MARK: - Animations
    // CAAnimation add trước khi view có window sẽ bị Core Animation bỏ qua — chỉ gọi
    // sau khi view đã lên màn (vd. trong `viewDidAppear`), không phải lúc khởi tạo.

    /// `ilignite` của design — lửa bùng từ 0 lên 1.22 rồi lắng về kích thước thật.
    /// Giữ nguyên trạng thái ẩn cho tới lúc animation bắt đầu (`fillMode = .backwards`).
    public func startIgniteAnimation(delay: TimeInterval, completion: (() -> Void)? = nil) {
        let beginTime = CACurrentMediaTime() + delay

        let ignite = CAKeyframeAnimation(keyPath: "transform.scale")
        ignite.values = [0.0, 1.22, 0.92, 1.0]
        ignite.keyTimes = [0.0, 0.42, 0.70, 1.0]
        ignite.duration = Self.igniteDuration
        ignite.beginTime = beginTime
        ignite.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.9, 0.3, 1.0)
        ignite.fillMode = .backwards
        ignite.isRemovedOnCompletion = true
        ignite.delegate = self
        bodyLayer.add(ignite, forKey: "ilIgnite")

        let igniteOpacity = CAKeyframeAnimation(keyPath: "opacity")
        igniteOpacity.values = [0.0, 1.0, 1.0]
        igniteOpacity.keyTimes = [0.0, 0.42, 1.0]
        igniteOpacity.duration = Self.igniteDuration
        igniteOpacity.beginTime = beginTime
        igniteOpacity.fillMode = .backwards
        igniteOpacity.isRemovedOnCompletion = true
        bodyLayer.add(igniteOpacity, forKey: "ilIgniteOpacity")

        pendingIgniteCompletion = completion
    }

    /// `ilpulse` của design áp lên ngọn lửa — nhịp thở nhẹ sau khi bùng.
    public func startPulsingAnimation(delay: TimeInterval = 0) {
        let pulse = CAKeyframeAnimation(keyPath: "opacity")
        pulse.values = [0.72, 1.0, 0.72]
        pulse.keyTimes = [0, 0.5, 1]
        pulse.duration = 2.6
        pulse.beginTime = CACurrentMediaTime() + delay
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        bodyLayer.add(pulse, forKey: "ilFlamePulse")
    }

    private static let igniteDuration: TimeInterval = 1.1
}

// MARK: - CAAnimationDelegate
extension ILFlameView: CAAnimationDelegate {
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        // Chỉ quan tâm animation bùng lửa — `ilFlamePulse` chạy vô hạn không bao giờ stop.
        guard flag, (anim as? CAKeyframeAnimation)?.keyPath == "transform.scale",
              let completion = pendingIgniteCompletion else { return }
        pendingIgniteCompletion = nil
        completion()
    }
}
