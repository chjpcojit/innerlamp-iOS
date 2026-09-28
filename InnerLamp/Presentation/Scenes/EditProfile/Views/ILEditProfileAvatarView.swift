//
//  ILEditProfileAvatarView.swift
//  InnerLamp
//

import UIKit

/// Avatar block at the top of the Edit Profile screen: an 88pt initials avatar with a round
/// camera badge on its bottom-right corner, and a "Đổi ảnh đại diện" link underneath.
/// Both the badge and the link fire `onChangeAvatar`.
final class ILEditProfileAvatarView: UIView {

    private enum Layout {
        static let avatarSize: CGFloat = 88
        static let badgeSize: CGFloat = 28
        static let badgeBorder: CGFloat = 2
        static let badgeOffset: CGFloat = 2
        static let cameraGlyphSize = CGSize(width: 10, height: 8)
        static let cameraGlyphBorder: CGFloat = 1.3
        static let linkTopGap: CGFloat = 12
    }

    // MARK: - Properties
    var onChangeAvatar: (() -> Void)?

    // MARK: - UI Elements
    private lazy var avatarView = ILAvatarView(initials: "", tone: .gold, size: Layout.avatarSize)

    private lazy var badgeButton: UIControl = {
        let control = UIControl()
        control.layer.cornerRadius = Layout.badgeSize / 2
        control.layer.borderWidth = Layout.badgeBorder
        control.isAccessibilityElement = true
        control.accessibilityTraits = .button
        control.accessibilityLabel = "editProfile.avatar.change".localized
        control.addTarget(self, action: #selector(handleChangeAvatar), for: .touchUpInside)
        return control
    }()

    private lazy var cameraGlyph: UIView = {
        let glyph = UIView()
        glyph.isUserInteractionEnabled = false
        glyph.layer.cornerRadius = ILMetrics.radiusGlyph
        glyph.layer.borderWidth = Layout.cameraGlyphBorder
        return glyph
    }()

    private lazy var changeButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = ILTypography.bodySmallMedium
        button.setTitleColor(ILColors.link, for: .normal)
        button.setTitle("editProfile.avatar.change".localized, for: .normal)
        button.addTarget(self, action: #selector(handleChangeAvatar), for: .touchUpInside)
        return button
    }()

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
        [avatarView, badgeButton, changeButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        cameraGlyph.translatesAutoresizingMaskIntoConstraints = false
        badgeButton.addSubview(cameraGlyph)

        NSLayoutConstraint.activate([
            avatarView.topAnchor.constraint(equalTo: topAnchor),
            avatarView.centerXAnchor.constraint(equalTo: centerXAnchor),

            badgeButton.widthAnchor.constraint(equalToConstant: Layout.badgeSize),
            badgeButton.heightAnchor.constraint(equalToConstant: Layout.badgeSize),
            badgeButton.trailingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: Layout.badgeOffset),
            badgeButton.bottomAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: Layout.badgeOffset),

            cameraGlyph.widthAnchor.constraint(equalToConstant: Layout.cameraGlyphSize.width),
            cameraGlyph.heightAnchor.constraint(equalToConstant: Layout.cameraGlyphSize.height),
            cameraGlyph.centerXAnchor.constraint(equalTo: badgeButton.centerXAnchor),
            cameraGlyph.centerYAnchor.constraint(equalTo: badgeButton.centerYAnchor),

            changeButton.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: Layout.linkTopGap),
            changeButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            changeButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Configure
    func configure(initials: String) {
        avatarView.initials = initials
    }

    // `layer.borderColor` is a static CGColor — refreshed manually on appearance change.
    private func applyDynamicColors() {
        badgeButton.backgroundColor = ILColors.ink
        // Ring matches the screen background so the badge looks cut out of the avatar.
        badgeButton.layer.borderColor = ILColors.canvasWarm.cgColor
        cameraGlyph.layer.borderColor = ILColors.canvas.cgColor
    }

    // MARK: - Actions
    @objc private func handleChangeAvatar() {
        onChangeAvatar?()
    }
}
