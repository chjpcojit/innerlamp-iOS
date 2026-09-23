//
//  ILImmersiveBackgroundView.swift
//  InnerLamp
//

import UIKit

/// Nền radial cho các màn immersive (Phiên thiền, Hoàn thành, Niệm Phật, Sen Vàng) — bộ token
/// `--il-med-bg`: sáng ở light mode, tối ở dark mode. Tâm gradient nằm ở 50% / 32% chiều cao,
/// mép ở 74% bán kính tới góc xa nhất (giống `radial-gradient(circle at 50% 32%, A, B 74%)`).
public final class ILImmersiveBackgroundView: UIView {

    public enum Style {
        /// `--il-med-bg`: light in light mode, dark in dark mode (center 50%/32%, edge 74%).
        case immersive
        /// Always-dark night background of the full-screen error popup
        /// (`radial-gradient(circle at 50% 34%, #2A241C, #100E0B 76%)`), independent of theme.
        case alwaysDarkAlert

        var centerPoint: CGPoint {
            switch self {
            case .immersive: return CGPoint(x: 0.5, y: 0.32)
            case .alwaysDarkAlert: return CGPoint(x: 0.5, y: 0.34)
            }
        }

        var edgeLocation: NSNumber {
            switch self {
            case .immersive: return 0.74
            case .alwaysDarkAlert: return 0.76
            }
        }

        var colors: (center: UIColor, edge: UIColor) {
            switch self {
            case .immersive: return (ILColors.medBackgroundCenter, ILColors.medBackgroundEdge)
            case .alwaysDarkAlert: return (ILColors.darkBackgroundTop, ILColors.darkBackground)
            }
        }
    }

    // MARK: - Properties
    private let style: Style

    // MARK: - UI Elements
    private let gradientLayer = CAGradientLayer()

    // MARK: - Initializer
    public override init(frame: CGRect) {
        self.style = .immersive
        super.init(frame: frame)
        setupViews()
    }

    public init(style: Style) {
        self.style = style
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        isUserInteractionEnabled = false
        gradientLayer.type = .radial
        gradientLayer.startPoint = style.centerPoint
        gradientLayer.locations = [0, style.edgeLocation]
        layer.addSublayer(gradientLayer)
        updateColors()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        guard bounds.width > 0, bounds.height > 0 else { return }

        // `.radial` dùng elip theo endPoint; đặt bán kính bằng khoảng cách tới góc xa nhất để ra
        // hình tròn (CSS `circle ... farthest-corner`).
        let centerPoint = style.centerPoint
        let center = CGPoint(x: bounds.width * centerPoint.x, y: bounds.height * centerPoint.y)
        let farthestX = max(center.x, bounds.width - center.x)
        let farthestY = max(center.y, bounds.height - center.y)
        let radius = hypot(farthestX, farthestY)
        gradientLayer.endPoint = CGPoint(
            x: centerPoint.x + radius / bounds.width,
            y: centerPoint.y + radius / bounds.height
        )
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateColors()
    }

    private func updateColors() {
        // CGColor không tự đảo theo trait — resolve thủ công theo appearance hiện tại.
        let colors = style.colors
        gradientLayer.colors = [
            colors.center.resolvedColor(with: traitCollection).cgColor,
            colors.edge.resolvedColor(with: traitCollection).cgColor
        ]
    }
}
