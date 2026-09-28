//
//  ILLampGlowView.swift
//  InnerLamp
//

import UIKit

/// Vòng tròn viền vàng + ngọn lửa phát sáng — biểu tượng "đèn" lặp lại ở nhiều màn
/// (Splash, Onboarding intro, Login, Paywall...). Kích thước cấu hình được qua `diameter`
/// để dùng ở cả icon nhỏ (Login) lẫn hero lớn (Onboarding intro).
///
/// Mọi tỉ lệ bên trong suy ra từ `diameter` theo đúng bảng của design handoff
/// (vòng 96px ↔ lửa 14×20, chân lửa cách đáy vòng 22px) nên vòng to hay nhỏ đều
/// giữ nguyên dáng.
public final class ILLampGlowView: UIView {

    // MARK: - Style
    /// Bảng màu của đèn theo nền màn chứa nó. Splash dùng `.splash` (đảo theo light/dark qua
    /// bộ `--il-spl-bd`/`--il-spl-halo`), Session/Paywall nằm trên nền tối, Login/Onboarding
    /// intro nằm trên nền sáng — design handoff cho mỗi bên mức alpha và sắc độ lửa khác nhau,
    /// nên khai báo tường minh thay vì đoán theo trait.
    public enum Style {
        /// Nền tối — viền `gold` 0.50, fill trong vòng `goldBright` 0.28, lửa `goldLight` → `goldBright`.
        case onDark
        /// Nền sáng — viền `gold` 0.45, fill trong vòng `goldBright` 0.24, lửa `goldSoft` → `goldBright`.
        case onLight
        /// Màn Splash — viền/fill đổi theo light/dark (`--il-spl-bd`/`--il-spl-halo`), lửa luôn
        /// `goldLight` → `goldBright` (theo design, ngọn lửa không đổi theo theme).
        case splash

        var borderColor: UIColor {
            switch self {
            case .onDark: return ILColors.goldBorderOnDark
            case .onLight: return ILColors.goldBorder
            case .splash: return ILColors.splashBorder
            }
        }

        var fillColor: UIColor {
            switch self {
            case .onDark: return ILColors.goldRingFill
            case .onLight: return ILColors.goldRingFillSoft
            case .splash: return ILColors.splashHalo
            }
        }

        var flameTopColor: UIColor {
            switch self {
            case .onDark, .splash: return ILColors.goldLight
            case .onLight: return ILColors.goldSoft
            }
        }
    }

    // MARK: - Tỉ lệ theo design (đơn vị: bội số của `diameter`)
    private enum Ratio {
        /// Chiều cao ngọn lửa: 20 / 96
        static let flameHeight = 20.0 / 96.0
        /// Khoảng cách từ chân lửa xuống đáy vòng: 22 / 96
        static let flameBottomInset = 22.0 / 96.0
    }

    // MARK: - UI Elements
    private let ring = UIView()
    /// Vầng sáng đổ bên trong vòng — `radial-gradient(circle at 50% 72%, …)` của design.
    private let ringFillLayer = CAGradientLayer()
    private let flameView: ILFlameView

    // MARK: - Constraints
    private let ringWidthConstraint: NSLayoutConstraint
    private let ringHeightConstraint: NSLayoutConstraint
    private let flameHeightConstraint: NSLayoutConstraint
    private let flameBottomConstraint: NSLayoutConstraint

    // MARK: - Properties
    public var diameter: CGFloat {
        didSet { applyMetrics() }
    }

    public let style: Style

    // MARK: - Initializer
    public init(diameter: CGFloat = 104, style: Style = .onDark) {
        self.diameter = diameter
        self.style = style
        self.flameView = ILFlameView(height: 20, topColor: style.flameTopColor)

        ringWidthConstraint = ring.widthAnchor.constraint(equalToConstant: diameter)
        ringHeightConstraint = ring.heightAnchor.constraint(equalToConstant: diameter)
        flameHeightConstraint = flameView.heightAnchor.constraint(
            equalToConstant: diameter * Ratio.flameHeight
        )
        flameBottomConstraint = flameView.bottomAnchor.constraint(
            equalTo: ring.bottomAnchor,
            constant: -diameter * Ratio.flameBottomInset
        )

        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear

        ring.translatesAutoresizingMaskIntoConstraints = false
        ring.clipsToBounds = false
        ring.layer.borderWidth = 1

        // Fill trong vòng: sáng nhất ở 72% chiều cao (ngay dưới chân lửa), tắt dần
        // ra mép — dùng gradient layer vì `CAGradientLayer` chỉ hỗ trợ radial đối xứng
        // qua `startPoint`/`endPoint`, đủ để tái tạo đúng cảm giác của design.
        ringFillLayer.type = .radial
        ringFillLayer.locations = [0.0, 0.68]
        ringFillLayer.startPoint = CGPoint(x: 0.5, y: 0.72)
        ringFillLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        ring.layer.addSublayer(ringFillLayer)

        ring.addSubview(flameView)
        addSubview(ring)

        applyStyleColors()

        NSLayoutConstraint.activate([
            ring.topAnchor.constraint(equalTo: topAnchor),
            ring.leadingAnchor.constraint(equalTo: leadingAnchor),
            ring.trailingAnchor.constraint(equalTo: trailingAnchor),
            ring.bottomAnchor.constraint(equalTo: bottomAnchor),
            ringWidthConstraint,
            ringHeightConstraint,
            flameView.centerXAnchor.constraint(equalTo: ring.centerXAnchor),
            flameBottomConstraint,
            flameHeightConstraint
        ])

        applyMetrics()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILLampGlowView, _) in
            view.applyColorAppearanceChange()
        }
    }

    private func applyMetrics() {
        ringWidthConstraint.constant = diameter
        ringHeightConstraint.constant = diameter
        flameHeightConstraint.constant = diameter * Ratio.flameHeight
        flameBottomConstraint.constant = -diameter * Ratio.flameBottomInset
        // `ILFlameView` cố định chiều rộng theo tỉ lệ 0.7 của chiều cao, nên đổi
        // chiều cao là đủ để lửa co giãn cùng vòng.
        ring.layer.cornerRadius = diameter / 2.0
        layoutIfNeeded()
    }

    // MARK: - Layout
    public override func layoutSubviews() {
        super.layoutSubviews()
        ringFillLayer.frame = ring.bounds
    }

    private func applyColorAppearanceChange() {
        applyStyleColors()
    }

    /// `ring.layer.borderColor` và `ringFillLayer.colors` không tự đảo theo trait — resolve lại
    /// theo appearance hiện tại. Chỉ `.splash` dùng màu động; `.onDark`/`.onLight` là màu cố
    /// định nên gọi lại vô hại.
    private func applyStyleColors() {
        ring.layer.borderColor = style.borderColor.resolvedColor(with: traitCollection).cgColor
        ringFillLayer.colors = [
            style.fillColor.resolvedColor(with: traitCollection).cgColor,
            ILColors.goldGlowClear.cgColor
        ]
    }

    // MARK: - Animations
    // CAAnimation add trước khi view có window sẽ bị Core Animation bỏ qua — chỉ gọi
    // sau khi view đã lên màn (vd. trong `viewDidAppear`), không phải lúc khởi tạo.

    /// `ilrise` + `ilignite` của design — cả vòng trồi lên trong khi lửa bùng sáng.
    ///
    /// `delay` áp cho vòng, `flameDelay` áp riêng cho ngọn lửa (Splash lệch nhau: vòng chồi
    /// ngay còn lửa bùng sau 0.25s). Bỏ trống `flameDelay` thì lửa bùng cùng nhịp vòng.
    /// `completion` chạy khi lửa bùng xong, dùng để nối tiếp các hiệu ứng sau đó.
    public func startIgniteAnimation(
        delay: TimeInterval = 0,
        flameDelay: TimeInterval? = nil,
        completion: (() -> Void)? = nil
    ) {
        let beginTime = CACurrentMediaTime() + delay

        let rise = CABasicAnimation(keyPath: "transform.translation.y")
        rise.fromValue = 10.0
        rise.toValue = 0.0
        rise.duration = Self.riseDuration
        rise.beginTime = beginTime
        rise.timingFunction = CAMediaTimingFunction(name: .easeOut)
        rise.fillMode = .backwards
        rise.isRemovedOnCompletion = true
        layer.add(rise, forKey: "ilRise")

        let riseOpacity = CABasicAnimation(keyPath: "opacity")
        riseOpacity.fromValue = 0.0
        riseOpacity.toValue = 1.0
        riseOpacity.duration = Self.riseDuration
        riseOpacity.beginTime = beginTime
        riseOpacity.timingFunction = CAMediaTimingFunction(name: .easeOut)
        riseOpacity.fillMode = .backwards
        riseOpacity.isRemovedOnCompletion = true
        layer.add(riseOpacity, forKey: "ilRiseOpacity")

        flameView.startIgniteAnimation(delay: flameDelay ?? delay, completion: completion)
    }

    /// Nhịp thở nhẹ của cả vòng đèn.
    public func startBreathingAnimation() {
        let breathe = CABasicAnimation(keyPath: "transform.scale")
        breathe.fromValue = 1.0
        breathe.toValue = 1.06
        breathe.duration = 4.0
        breathe.autoreverses = true
        breathe.repeatCount = .infinity
        breathe.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(breathe, forKey: "ilBreathe")
    }

    /// `ilpulse` của design áp riêng lên ngọn lửa — lửa lung linh trong khi vòng đứng yên.
    public func startFlickerAnimation(delay: TimeInterval = 0) {
        flameView.startPulsingAnimation(delay: delay)
    }

    private static let riseDuration: TimeInterval = 0.7
}
