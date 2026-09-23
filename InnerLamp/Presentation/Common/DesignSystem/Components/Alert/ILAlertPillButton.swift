//
//  ILAlertPillButton.swift
//  InnerLamp
//

import UIKit

/// Pill button used inside the error popups where `ILButton` (50pt, 13.5px) does not match the
/// design: the compact pills on the action banner, the side-by-side pills on the dialog and the
/// light-on-dark pills on the full-screen error. The bottom sheet uses `ILButton` directly.
public final class ILAlertPillButton: UIControl {

    public enum Style {
        case bannerPrimary
        case bannerSecondary
        case dialogPrimary
        case dialogSecondary
        case fullPrimary
        case fullSecondary
    }

    // MARK: - Properties
    public var onTap: (() -> Void)?

    private let style: Style

    // MARK: - UI Elements
    private let titleLabel = UILabel()

    // MARK: - Initializer
    public init(title: String, style: Style) {
        self.style = style
        super.init(frame: .zero)
        titleLabel.text = title
        accessibilityLabel = title
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        isAccessibilityElement = true
        accessibilityTraits = .button

        titleLabel.textAlignment = .center
        titleLabel.isUserInteractionEnabled = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        switch style {
        case .bannerPrimary, .bannerSecondary:
            let padding = ILMetrics.Alert.bannerButtonPadding
            titleLabel.font = ILTypography.bodySmallMedium
            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: padding.top),
                titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding.bottom),
                titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding.left),
                titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding.right)
            ])
        case .dialogPrimary, .dialogSecondary, .fullPrimary, .fullSecondary:
            let isDialog = style == .dialogPrimary || style == .dialogSecondary
            titleLabel.font = isDialog ? ILTypography.alertDialogButton : ILTypography.alertFullButton
            let height = isDialog ? ILMetrics.Alert.dialogButtonHeight : ILMetrics.Alert.fullButtonHeight
            NSLayoutConstraint.activate([
                heightAnchor.constraint(equalToConstant: height),
                titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
                titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: ILMetrics.spaceSmall),
                titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -ILMetrics.spaceSmall),
                titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
            ])
        }

        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)

        updateAppearance()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    private func updateAppearance() {
        let background: UIColor
        let border: UIColor?
        let titleColor: UIColor

        switch style {
        case .bannerPrimary:
            background = ILColors.alertBannerInk
            border = nil
            titleColor = ILColors.alertBannerButtonInk
        case .bannerSecondary:
            background = .clear
            border = ILColors.Alert.bannerSecondaryBorder
            titleColor = ILColors.Alert.bannerSecondaryLabel
        case .dialogPrimary:
            background = ILColors.ink
            border = nil
            titleColor = ILColors.canvas
        case .dialogSecondary:
            background = .clear
            border = ILColors.Alert.hairline
            titleColor = ILColors.Alert.secondaryLabel
        case .fullPrimary:
            background = ILColors.inkOnDark
            border = nil
            titleColor = ILColors.nightInk
        case .fullSecondary:
            background = .clear
            border = ILColors.Alert.fullBorder
            titleColor = ILColors.Alert.fullSecondaryLabel
        }

        backgroundColor = background
        titleLabel.textColor = titleColor
        layer.borderWidth = border == nil ? 0 : 1
        // CGColor does not follow trait changes — resolved against the current trait here and
        // refreshed in `traitCollectionDidChange`.
        layer.borderColor = border?.resolvedColor(with: traitCollection).cgColor
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateAppearance()
    }

    // MARK: - Touch Animations
    @objc private func handleTouchDown() {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = CGAffineTransform(scaleX: 0.978, y: 0.978)
        }
    }

    @objc private func handleTouchUp() {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = .identity
        }
    }

    @objc private func handleTapAction() {
        onTap?()
    }
}
