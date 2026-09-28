//
//  ILSutraDetailHeroView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import UIKit

/// Hero tối (luôn tối ở cả light/dark) của màn Chi tiết bài kinh — khớp `isDetail` trong design
/// handoff: nền gradient tối + quầng sáng, nút ‹, pill "Tải về máy", eyebrow, tiêu đề Lora, dòng
/// meta và các chip thông tin. Chỉ nhận chuỗi nên không phụ thuộc nội dung cụ thể của 1 bộ kinh.
final class ILSutraDetailHeroView: UIView {

    private enum Layout {
        static let topBarPadding: CGFloat = 20
        static let horizontalInset: CGFloat = 22
        static let bottomInset: CGFloat = 26
        static let glowDiameter: CGFloat = 320
    }

    // MARK: - Properties
    /// Khoảng cách từ mép trên màn hình tới hàng nút ‹/Tải về máy (bằng safe area top + padding).
    var topInset: CGFloat = 0 {
        didSet { topBarTopConstraint?.constant = topInset + Layout.topBarPadding }
    }

    var onBack: (() -> Void)?
    var onDownload: (() -> Void)?

    // MARK: - UI Elements
    private let gradientLayer = CAGradientLayer()
    private let glowLayer = CAGradientLayer()

    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setAttributedTitle(
            ILTypography.makeAttributedString(
                text: "‹",
                font: ILTypography.chevron,
                color: ILColors.inkOnDarkSecondary,
                alignment: .center
            ),
            for: .normal
        )
        button.accessibilityLabel = "common.back".localized
        button.addTarget(self, action: #selector(handleBackTap), for: .touchUpInside)
        return button
    }()

    private lazy var downloadButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = ILColors.inkOnDark.withAlphaComponent(0.70)
        config.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 13, bottom: 7, trailing: 13)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = ILTypography.label
            return outgoing
        }
        config.cornerStyle = .capsule
        config.background.strokeWidth = 1
        config.background.strokeColor = ILColors.inkOnDark.withAlphaComponent(0.22)
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(handleDownloadTap), for: .touchUpInside)
        return button
    }()

    private lazy var kickerLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        return label
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.contentHeroTitle
        label.textColor = ILColors.inkOnDark
        label.numberOfLines = 0
        return label
    }()

    private lazy var metaLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.bodySmall
        label.textColor = ILColors.inkOnDark.withAlphaComponent(0.55)
        label.numberOfLines = 0
        return label
    }()

    private lazy var tagsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = ILMetrics.spaceSmall
        stack.alignment = .center
        return stack
    }()

    private var topBarTopConstraint: NSLayoutConstraint?

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration
    func configure(
        kicker: String,
        title: String,
        metaText: String,
        tags: [ILSutraDetailTagModel],
        downloadTitle: String
    ) {
        kickerLabel.attributedText = ILTypography.makeAttributedString(
            text: kicker,
            font: ILTypography.eyebrowSmall,
            color: ILColors.goldOnDarkStrong,
            letterSpacingEm: 0.16
        )
        titleLabel.text = title
        metaLabel.text = metaText
        downloadButton.configuration?.title = downloadTitle
        rebuildTags(tags)
    }

    private func rebuildTags(_ tags: [ILSutraDetailTagModel]) {
        tagsStack.arrangedSubviews.forEach {
            tagsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for tag in tags {
            tagsStack.addArrangedSubview(makeTagPill(tag))
        }
    }

    private func makeTagPill(_ tag: ILSutraDetailTagModel) -> UIView {
        let label = UILabel()
        label.font = ILTypography.captionMedium
        label.text = tag.title
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        let pill = UIView()
        pill.layer.cornerRadius = ILMetrics.radiusPill
        pill.layer.borderWidth = 1
        if tag.isFilled {
            pill.backgroundColor = ILColors.goldBright.withAlphaComponent(0.16)
            pill.layer.borderColor = UIColor.clear.cgColor
            label.textColor = ILColors.goldOnDark
        } else {
            pill.backgroundColor = .clear
            pill.layer.borderColor = ILColors.inkOnDark.withAlphaComponent(0.18).cgColor
            label.textColor = ILColors.inkOnDarkSecondary
        }
        pill.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: pill.topAnchor, constant: 6),
            label.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -6),
            label.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -12)
        ])
        return pill
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = true

        gradientLayer.colors = [ILColors.darkBackgroundTop.cgColor, ILColors.darkBackground.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.3, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.7, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)

        glowLayer.type = .radial
        glowLayer.colors = [ILColors.goldGlowStrong.cgColor, ILColors.goldGlowClear.cgColor]
        glowLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        glowLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(glowLayer, above: gradientLayer)

        [backButton, downloadButton, kickerLabel, titleLabel, metaLabel, tagsStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        topBarTopConstraint = backButton.topAnchor.constraint(equalTo: topAnchor, constant: Layout.topBarPadding)

        NSLayoutConstraint.activate([
            topBarTopConstraint!,
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalInset),
            backButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
            backButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),

            downloadButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            downloadButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalInset),

            kickerLabel.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 24),
            kickerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalInset),
            kickerLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalInset),

            titleLabel.topAnchor.constraint(equalTo: kickerLabel.bottomAnchor, constant: ILMetrics.rowSpacing),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalInset),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalInset),

            metaLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: ILMetrics.rowSpacing),
            metaLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalInset),
            metaLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalInset),

            tagsStack.topAnchor.constraint(equalTo: metaLabel.bottomAnchor, constant: 18),
            tagsStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalInset),
            tagsStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -Layout.horizontalInset),
            tagsStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.bottomInset)
        ])
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        let glowSize = Layout.glowDiameter
        glowLayer.frame = CGRect(
            x: bounds.midX - glowSize / 2,
            y: -glowSize / 2 + 40,
            width: glowSize,
            height: glowSize
        )
        glowLayer.cornerRadius = glowSize / 2
    }

    @objc private func handleBackTap() {
        onBack?()
    }

    @objc private func handleDownloadTap() {
        onDownload?()
    }
}
