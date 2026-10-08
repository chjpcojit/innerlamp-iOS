//
//  ILLanguageThemeTileView.swift
//  InnerLamp
//

import UIKit

/// One appearance choice (Sáng / Tối / Theo máy): a swatch preview above its label. The swatch is
/// the same in both system modes — it previews the theme being chosen, not the current one.
final class ILLanguageThemeTileView: UIControl {

    // MARK: - Properties
    var onTap: (() -> Void)?

    override var isSelected: Bool {
        didSet { updateAppearance() }
    }

    // MARK: - UI Elements
    private let swatchView = ILLanguageThemeSwatchView()
    private let titleLabel = UILabel()

    // MARK: - Initializer
    init(theme: ILSettingsThemeMode) {
        super.init(frame: .zero)
        swatchView.theme = theme
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        layer.cornerRadius = ILMetrics.radiusCardRegular
        layer.borderWidth = 1

        titleLabel.font = ILTypography.bodySmallMedium
        titleLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [swatchView, titleLabel])
        stack.axis = .vertical
        stack.spacing = 10
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            swatchView.heightAnchor.constraint(equalToConstant: 46),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: ILMetrics.spaceMedium),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.spaceMedium),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.spaceMedium),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -ILMetrics.spaceMedium)
        ])

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        updateAppearance()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILLanguageThemeTileView, _) in
            view.updateAppearance()
        }
    }

    // MARK: - Configure
    func configure(title: String, isSelected: Bool) {
        titleLabel.text = title
        accessibilityLabel = title
        self.isSelected = isSelected
    }

    private func updateAppearance() {
        backgroundColor = ILColors.surface
        layer.borderColor = (isSelected ? ILColors.goldBorder : ILColors.border).cgColor
        titleLabel.textColor = isSelected ? ILColors.link : ILColors.inkDim
        accessibilityTraits = isSelected ? [.button, .selected] : .button
        swatchView.setNeedsLayout()
    }

    @objc private func handleTap() {
        onTap?()
    }
}

/// Gradient preview of a theme. Colors are resolved against a fixed light/dark trait so the swatch
/// keeps showing "light" / "dark" regardless of the current appearance.
private final class ILLanguageThemeSwatchView: UIView {

    var theme: ILSettingsThemeMode = .system {
        didSet { applyColors() }
    }

    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.masksToBounds = true
        isUserInteractionEnabled = false
        layer.addSublayer(gradientLayer)
        applyColors()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILLanguageThemeSwatchView, _) in
            view.applyColors()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    private func applyColors() {
        layer.borderColor = ILColors.border.cgColor
        let lightTraits = UITraitCollection(userInterfaceStyle: .light)
        let lightStart = ILColors.canvasWarm.resolvedColor(with: lightTraits).cgColor
        let lightEnd = ILColors.canvasWarmEnd1.resolvedColor(with: lightTraits).cgColor
        let darkStart = ILColors.darkBackgroundTop.cgColor
        let darkEnd = ILColors.darkBackground.cgColor

        switch theme {
        case .light:
            gradientLayer.colors = [lightStart, lightEnd]
            gradientLayer.locations = [0, 1]
            gradientLayer.startPoint = CGPoint(x: 0.2, y: 0)
            gradientLayer.endPoint = CGPoint(x: 0.8, y: 1)
        case .dark:
            gradientLayer.colors = [darkStart, darkEnd]
            gradientLayer.locations = [0, 1]
            gradientLayer.startPoint = CGPoint(x: 0.2, y: 0)
            gradientLayer.endPoint = CGPoint(x: 0.8, y: 1)
        case .system:
            // Hard split: left half light, right half dark.
            gradientLayer.colors = [lightStart, lightStart, darkStart, darkStart]
            gradientLayer.locations = [0, 0.5, 0.5, 1]
            gradientLayer.startPoint = CGPoint(x: 0, y: 0.4)
            gradientLayer.endPoint = CGPoint(x: 1, y: 0.6)
        }
    }
}
