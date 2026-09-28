//
//  ILNotificationsHeroCardView.swift
//  InnerLamp
//

import UIKit

/// Thẻ "Sắp diễn ra" đầu màn Thông báo: nền tối luôn tối ở cả light/dark (theo design handoff),
/// eyebrow vàng, tiêu đề serif, vầng sáng góc trên phải, và hai nút pill — "Ngồi ngay" (vàng) và
/// "Bỏ qua tối nay" (ghost). Nội dung riêng màn Thông báo.
final class ILNotificationsHeroCardView: UIView {

    // MARK: - Constants
    private enum Layout {
        static let horizontalPadding: CGFloat = 22
        static let verticalPadding: CGFloat = 20
        static let glyphSize: CGFloat = 13
        static let glowSize: CGFloat = 170
    }

    // MARK: - Properties
    var eyebrow: String = "" {
        didSet { renderEyebrow() }
    }

    var title: String = "" {
        didSet { renderTitle() }
    }

    var onSitNow: (() -> Void)?
    var onSkip: (() -> Void)?

    // MARK: - UI Elements
    private let gradientLayer = CAGradientLayer()
    private let glowLayer = CAGradientLayer()

    private lazy var eyebrowLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        return label
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private lazy var sitNowButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "notifications.hero.cta.sit".localized
        config.baseForegroundColor = ILColors.lampFlameDark
        config.contentInsets = NSDirectionalEdgeInsets(top: 9, leading: 16, bottom: 9, trailing: 16)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = ILTypography.bodySmallMedium
            return outgoing
        }
        config.cornerStyle = .capsule
        config.background.backgroundColor = ILColors.goldBright
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(handleSitNow), for: .touchUpInside)
        return button
    }()

    private lazy var skipButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "notifications.hero.cta.skip".localized
        config.baseForegroundColor = ILColors.inkOnDarkStrong
        config.contentInsets = NSDirectionalEdgeInsets(top: 9, leading: 16, bottom: 9, trailing: 16)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = ILTypography.bodySmallMedium
            return outgoing
        }
        config.cornerStyle = .capsule
        config.background.strokeWidth = 1
        config.background.strokeColor = ILColors.inkOnDarkBorderSoft
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(handleSkip), for: .touchUpInside)
        return button
    }()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        glowLayer.frame = CGRect(
            x: bounds.width - Layout.glowSize + 40,
            y: -Layout.glowSize + 50,
            width: Layout.glowSize,
            height: Layout.glowSize
        )
        glowLayer.cornerRadius = Layout.glowSize / 2
    }

    // MARK: - Setup
    private func setupViews() {
        layer.cornerRadius = ILMetrics.radiusCardSmall + 4
        clipsToBounds = true

        gradientLayer.colors = [ILColors.darkBackgroundTop.cgColor, ILColors.darkBackground.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.2, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.8, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)

        glowLayer.type = .radial
        glowLayer.colors = [ILColors.goldGlowStrong.cgColor, ILColors.goldGlowClear.cgColor]
        glowLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        glowLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(glowLayer, above: gradientLayer)

        let buttonRow = UIStackView(arrangedSubviews: [sitNowButton, skipButton, UIView()])
        buttonRow.axis = .horizontal
        buttonRow.alignment = .center
        buttonRow.spacing = ILMetrics.rowSpacing

        let contentStack = UIStackView(arrangedSubviews: [eyebrowLabel, titleLabel, buttonRow])
        contentStack.axis = .vertical
        contentStack.alignment = .leading
        contentStack.spacing = 0
        contentStack.isUserInteractionEnabled = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.setCustomSpacing(10, after: eyebrowLabel)
        contentStack.setCustomSpacing(16, after: titleLabel)
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: Layout.verticalPadding),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.verticalPadding),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalPadding),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalPadding)
        ])
    }

    private func renderEyebrow() {
        eyebrowLabel.attributedText = ILTypography.makeAttributedString(
            text: eyebrow.uppercased(),
            font: ILTypography.eyebrowSmall,
            color: ILColors.goldOnDarkStrong,
            letterSpacingEm: 0.16
        )
    }

    private func renderTitle() {
        titleLabel.attributedText = ILTypography.makeAttributedString(
            text: title,
            font: ILTypography.heroCardTitle,
            color: ILColors.inkOnDark,
            lineHeightMultiple: 1.4
        )
    }

    // MARK: - Actions
    @objc private func handleSitNow() {
        onSitNow?()
    }

    @objc private func handleSkip() {
        onSkip?()
    }
}
