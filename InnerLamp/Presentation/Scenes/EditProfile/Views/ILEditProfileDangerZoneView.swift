//
//  ILEditProfileDangerZoneView.swift
//  InnerLamp
//

import UIKit

/// "Vùng cẩn trọng" block at the bottom of the Edit Profile screen: a muted caption followed by two
/// full-width action cards — "Đổi mật khẩu" (neutral) and "Xóa tài khoản và toàn bộ dữ liệu"
/// (destructive, danger text + border).
final class ILEditProfileDangerZoneView: UIView {

    private enum Layout {
        static let captionGap: CGFloat = 10
        static let cardInsets = NSDirectionalEdgeInsets(top: 15, leading: 16, bottom: 15, trailing: 16)
    }

    // MARK: - Properties
    var onChangePassword: (() -> Void)?
    var onDeleteAccount: (() -> Void)?

    // MARK: - UI Elements
    private lazy var captionLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.inkMuted
        label.text = "editProfile.dangerZone.title".localized
        return label
    }()

    private lazy var changePasswordButton = makeCardButton(
        title: "editProfile.dangerZone.changePassword".localized,
        textColor: ILColors.ink,
        action: #selector(handleChangePassword)
    )

    private lazy var deleteAccountButton = makeCardButton(
        title: "editProfile.dangerZone.deleteAccount".localized,
        textColor: ILColors.danger,
        action: #selector(handleDeleteAccount)
    )

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
        applyDynamicColors()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.applyDynamicColors()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        let stack = UIStackView(arrangedSubviews: [captionLabel, changePasswordButton, deleteAccountButton])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = ILMetrics.rowSpacing
        stack.setCustomSpacing(Layout.captionGap, after: captionLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    private func makeCardButton(title: String, textColor: UIColor, action: Selector) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = Layout.cardInsets
        configuration.titleAlignment = .leading
        configuration.baseForegroundColor = textColor
        configuration.background.backgroundColor = ILColors.surface
        configuration.background.cornerRadius = ILMetrics.radiusField
        configuration.background.strokeWidth = 1
        configuration.attributedTitle = AttributedString(
            title,
            attributes: AttributeContainer([.font: ILTypography.sectionTitle])
        )

        let button = UIButton(configuration: configuration)
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    // Stroke colors are resolved once into the configuration — refresh on appearance change.
    private func applyDynamicColors() {
        changePasswordButton.configuration?.background.strokeColor = ILColors.borderMedium
        deleteAccountButton.configuration?.background.strokeColor = ILColors.dangerBorder
    }

    // MARK: - Actions
    @objc private func handleChangePassword() {
        onChangePassword?()
    }

    @objc private func handleDeleteAccount() {
        onDeleteAccount?()
    }
}
