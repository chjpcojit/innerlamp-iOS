//
//  ILSplashEmberFieldView.swift
//  InnerLamp
//

import UIKit

/// Ba hạt than hồng bay lên từ đáy vòng đèn rồi tan biến — chi tiết "lửa còn ấm" của màn Splash.
///
/// Tách khỏi `ILSplashAmbienceView` vì z-order khác nhau: design đặt hạt **trong lòng** vòng đèn
/// nên chúng phải vẽ trên vòng, còn ripple/tia sáng nằm dưới.
///
/// Vị trí hạt neo theo vòng đèn chứ không theo màn hình — gọi `alignEmbers(to:ringDiameter:)` sau
/// khi cả hai view đã vào chung một cây view (Auto Layout cho phép ràng buộc khác nhánh miễn có
/// tổ tiên chung).
final class ILSplashEmberFieldView: UIView {

    // MARK: - Spec
    private struct EmberSpec {
        let diameter: CGFloat
        let color: UIColor
        /// Vị trí ngang theo bội số đường kính vòng đèn (`left` 50% / 40% / 60% của design).
        let horizontalRatio: CGFloat
        let duration: TimeInterval
        let delay: TimeInterval
    }

    private enum Metrics {
        /// Hạt xuất phát từ `bottom:30px` tính từ đáy vòng đèn.
        static let bottomInset: CGFloat = 30
        /// Quãng bay lên `translateY(-190px)`.
        static let riseDistance: CGFloat = 190
    }

    private static let specs: [EmberSpec] = [
        EmberSpec(diameter: 3.0, color: ILColors.goldLight, horizontalRatio: 0.50, duration: 4.2, delay: 0.9),
        EmberSpec(diameter: 2.0, color: ILColors.goldEmber, horizontalRatio: 0.40, duration: 4.6, delay: 1.9),
        EmberSpec(diameter: 2.5, color: ILColors.goldSoft, horizontalRatio: 0.60, duration: 5.0, delay: 2.8)
    ]

    // MARK: - UI Elements
    private let emberViews: [UIView]
    private var hasAlignedEmbers = false

    // MARK: - Initializer
    init() {
        emberViews = Self.specs.map { spec in
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.isUserInteractionEnabled = false
            view.backgroundColor = spec.color
            view.layer.cornerRadius = spec.diameter / 2.0
            return view
        }

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

        for (index, ember) in emberViews.enumerated() {
            let spec = Self.specs[index]
            addSubview(ember)
            NSLayoutConstraint.activate([
                ember.widthAnchor.constraint(equalToConstant: spec.diameter),
                ember.heightAnchor.constraint(equalToConstant: spec.diameter)
            ])
        }
    }

    /// Ghim ba hạt vào đáy vòng đèn. Gọi đúng một lần, sau khi view này và `ringView` đã có tổ
    /// tiên chung trong cây view.
    func alignEmbers(to ringView: UIView, ringDiameter: CGFloat) {
        guard !hasAlignedEmbers else { return }
        hasAlignedEmbers = true

        for (index, ember) in emberViews.enumerated() {
            let spec = Self.specs[index]
            let horizontalOffset = (spec.horizontalRatio - 0.5) * ringDiameter
            NSLayoutConstraint.activate([
                ember.centerXAnchor.constraint(equalTo: ringView.centerXAnchor, constant: horizontalOffset),
                ember.bottomAnchor.constraint(equalTo: ringView.bottomAnchor, constant: -Metrics.bottomInset)
            ])
        }
    }

    // MARK: - Animations
    // CAAnimation add trước khi view có window sẽ bị Core Animation bỏ qua — chỉ gọi sau khi
    // view đã lên màn (vd. trong `viewDidAppear`), không phải lúc khởi tạo.

    /// `ilember`: hạt bay lên 190pt, lớn dần từ 0.6 lên 1, sáng nhất ở 18% hành trình rồi tắt.
    func startAnimations() {
        let beginTime = CACurrentMediaTime()

        for (index, ember) in emberViews.enumerated() {
            let spec = Self.specs[index]
            let emberBeginTime = beginTime + spec.delay

            // `fillMode = .backwards` giữ giá trị keyframe đầu trong suốt `delay` — không có nó,
            // layer không bị animation chi phối trước `beginTime` nên render opacity mặc định (1)
            // và hạt hiện sẵn ở đáy vòng đèn trước khi kịp bay lên.
            let rise = CAKeyframeAnimation(keyPath: "transform.translation.y")
            rise.values = [0.0, -Metrics.riseDistance]
            rise.keyTimes = [0.0, 1.0]
            rise.duration = spec.duration
            rise.beginTime = emberBeginTime
            rise.repeatCount = .infinity
            rise.fillMode = .backwards
            rise.timingFunction = CAMediaTimingFunction(name: .easeOut)
            ember.layer.add(rise, forKey: "ilEmberRise")

            let grow = CAKeyframeAnimation(keyPath: "transform.scale")
            grow.values = [0.6, 1.0]
            grow.keyTimes = [0.0, 1.0]
            grow.duration = spec.duration
            grow.beginTime = emberBeginTime
            grow.repeatCount = .infinity
            grow.fillMode = .backwards
            grow.timingFunction = CAMediaTimingFunction(name: .easeOut)
            ember.layer.add(grow, forKey: "ilEmberGrow")

            let fade = CAKeyframeAnimation(keyPath: "opacity")
            fade.values = [0.0, 0.85, 0.0]
            fade.keyTimes = [0.0, 0.18, 1.0]
            fade.duration = spec.duration
            fade.beginTime = emberBeginTime
            fade.repeatCount = .infinity
            fade.fillMode = .backwards
            ember.layer.add(fade, forKey: "ilEmberFade")
        }
    }
}
