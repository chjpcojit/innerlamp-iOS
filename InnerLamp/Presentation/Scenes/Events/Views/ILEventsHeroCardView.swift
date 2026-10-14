//
//  ILEventsHeroCardView.swift
//  InnerLamp
//

import UIKit

/// Thẻ "Sắp diễn ra" đầu màn Sự kiện & khóa học: nền tối luôn tối ở cả light/dark (theo design
/// handoff), ô ngày bên trái, eyebrow vàng, tiêu đề serif 2 dòng, mô tả phụ, và hàng dưới gồm nút
/// "Ghi danh" (pill sáng) + "còn N chỗ". Biết `ILEventsFeaturedModel` nên thuộc riêng màn Sự kiện.
final class ILEventsHeroCardView: UIView {

    // MARK: - Constants
    private enum Layout {
        static let padding: CGFloat = 22
        static let tileWidth: CGFloat = 58
        static let tileRadius: CGFloat = 16
        static let tileVerticalPadding: CGFloat = 10
        static let tileGap: CGFloat = 16
        static let glowSize: CGFloat = 240
    }

    // MARK: - Properties
    var onRegister: (() -> Void)?

    // MARK: - UI Elements
    private let gradientLayer = CAGradientLayer()
    private let glowLayer = CAGradientLayer()

    private lazy var dateTile: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ILColors.inkOnDark.withAlphaComponent(0.08)
        view.layer.cornerRadius = Layout.tileRadius
        view.layer.borderWidth = 1
        view.layer.borderColor = ILColors.goldBright.withAlphaComponent(0.30).cgColor
        return view
    }()

    private lazy var dayLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.scriptureTitle
        label.textColor = ILColors.inkOnDark
        label.textAlignment = .center
        return label
    }()

    private lazy var monthLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()

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

    private lazy var metaLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private lazy var registerButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = ILTypography.button
        button.setTitleColor(ILColors.nightInk, for: .normal)
        button.backgroundColor = ILColors.inkOnDark
        button.layer.cornerRadius = ILMetrics.radiusPill
        button.addTarget(self, action: #selector(handleRegister), for: .touchUpInside)
        return button
    }()

    private lazy var seatsLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.inkOnDarkTertiary
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
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
            x: bounds.width - Layout.glowSize + 70,
            y: -Layout.glowSize + 60,
            width: Layout.glowSize,
            height: Layout.glowSize
        )
        glowLayer.cornerRadius = Layout.glowSize / 2
    }

    // MARK: - Setup
    private func setupViews() {
        layer.cornerRadius = ILMetrics.radiusCardLarge
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

        let dateStack = UIStackView(arrangedSubviews: [dayLabel, monthLabel])
        dateStack.axis = .vertical
        dateStack.spacing = 2
        dateStack.alignment = .center
        dateStack.translatesAutoresizingMaskIntoConstraints = false
        dateTile.addSubview(dateStack)

        let contentColumn = UIStackView(arrangedSubviews: [eyebrowLabel, titleLabel, metaLabel])
        contentColumn.axis = .vertical
        contentColumn.alignment = .leading
        contentColumn.spacing = 0
        contentColumn.setCustomSpacing(7, after: eyebrowLabel)
        contentColumn.setCustomSpacing(8, after: titleLabel)

        let topRow = UIStackView(arrangedSubviews: [dateTile, contentColumn])
        topRow.axis = .horizontal
        topRow.alignment = .top
        topRow.spacing = Layout.tileGap

        let bottomRow = UIStackView(arrangedSubviews: [registerButton, seatsLabel])
        bottomRow.axis = .horizontal
        bottomRow.alignment = .center
        bottomRow.spacing = ILMetrics.spaceMedium

        let contentStack = UIStackView(arrangedSubviews: [topRow, bottomRow])
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = ILMetrics.groupSpacing
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            dateTile.widthAnchor.constraint(equalToConstant: Layout.tileWidth),

            registerButton.heightAnchor.constraint(equalToConstant: ILMetrics.buttonHeight),

            dateStack.topAnchor.constraint(equalTo: dateTile.topAnchor, constant: Layout.tileVerticalPadding),
            dateStack.bottomAnchor.constraint(equalTo: dateTile.bottomAnchor, constant: -Layout.tileVerticalPadding),
            dateStack.leadingAnchor.constraint(equalTo: dateTile.leadingAnchor, constant: 4),
            dateStack.trailingAnchor.constraint(equalTo: dateTile.trailingAnchor, constant: -4),

            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: Layout.padding - 2),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -(Layout.padding - 2)),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.padding),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.padding)
        ])
    }

    // MARK: - Configure
    func configure(with model: ILEventsFeaturedModel) {
        dayLabel.text = model.day
        monthLabel.attributedText = ILTypography.makeAttributedString(
            text: model.monthLabel.uppercased(),
            font: ILTypography.eyebrow,
            color: ILColors.inkOnDarkSecondary,
            letterSpacingEm: 0.12
        )
        eyebrowLabel.attributedText = ILTypography.makeAttributedString(
            text: model.eyebrowText.uppercased(),
            font: ILTypography.eyebrowSmall,
            color: ILColors.goldOnDarkStrong,
            letterSpacingEm: 0.16
        )
        titleLabel.attributedText = ILTypography.makeAttributedString(
            text: model.title,
            font: ILTypography.scriptureTitle,
            color: ILColors.inkOnDark,
            lineHeightMultiple: 1.3
        )
        metaLabel.attributedText = ILTypography.makeAttributedString(
            text: model.metaText,
            font: ILTypography.note,
            color: ILColors.inkOnDarkSecondary,
            lineHeightMultiple: 1.7
        )
        registerButton.setTitle(model.ctaTitle, for: .normal)
        seatsLabel.text = model.seatsText
    }

    // MARK: - Actions
    @objc private func handleRegister() {
        onRegister?()
    }
}
