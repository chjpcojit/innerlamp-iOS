//
//  ILSutraDetailHeroView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import UIKit

/// Hero theme-aware (bộ `--il-th-*`, đổi theo light/dark) của màn Chi tiết bài kinh — khớp
/// `isDetail` trong design handoff: nền gradient `th-bg` tan vào `canvas` + quầng sáng elip,
/// eyebrow, tiêu đề Lora, tên nguyên ngữ nghiêng, dòng meta và hàng chip (tự xuống dòng).
///
/// Header (‹ và "Tải về máy") không nằm ở đây mà là `ILNavBar` ghim trên cùng trong
/// `ILSutraDetailViewController`; hero chỉ nhận chuỗi nên không phụ thuộc nội dung 1 bộ kinh.
final class ILSutraDetailHeroView: UIView {

    private enum Layout {
        static let horizontalInset: CGFloat = 20
        static let topInset: CGFloat = 24
        static let bottomInset: CGFloat = 30
    }

    // MARK: - UI Elements
    private let gradientLayer = CAGradientLayer()
    private let glowLayer = CAGradientLayer()

    private lazy var kickerLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        return label
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.contentHeroTitle
        label.textColor = ILColors.templeHeaderInk
        label.numberOfLines = 0
        return label
    }()

    private lazy var originalNameLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.heroSubtitleItalic
        label.textColor = ILColors.templeHeaderSub
        label.numberOfLines = 0
        return label
    }()

    private lazy var metaLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.bodySmall
        label.textColor = ILColors.templeHeaderSub
        label.numberOfLines = 0
        return label
    }()

    private let tagsFlow = ILChipFlowView(rowSpacing: ILMetrics.spaceSmall, itemSpacing: ILMetrics.spaceSmall)

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [kickerLabel, titleLabel, originalNameLabel, metaLabel, tagsFlow])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 0
        stack.setCustomSpacing(10, after: kickerLabel)
        stack.setCustomSpacing(6, after: titleLabel)
        stack.setCustomSpacing(10, after: originalNameLabel)
        stack.setCustomSpacing(18, after: metaLabel)
        stack.isUserInteractionEnabled = false
        return stack
    }()

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
        originalName: String,
        metaText: String,
        tags: [ILSutraDetailTagModel]
    ) {
        kickerLabel.attributedText = ILTypography.makeAttributedString(
            text: kicker,
            font: ILTypography.eyebrowSmall,
            color: ILColors.heroAccent,
            letterSpacingEm: 0.16
        )
        titleLabel.text = title
        originalNameLabel.text = originalName
        originalNameLabel.isHidden = originalName.isEmpty
        metaLabel.text = metaText
        tagsFlow.setItems(tags.map { makeTagPill($0) })
        tagsFlow.isHidden = tags.isEmpty
    }

    private func makeTagPill(_ tag: ILSutraDetailTagModel) -> UIView {
        let label = UILabel()
        label.font = ILTypography.captionMedium
        label.text = tag.title
        label.textColor = ILColors.heroAccent
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        let pill = ILSutraDetailTagPillView(isFilled: tag.isFilled)
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

        // Nền `--il-th-bg`: 3 chặng gradient tan dần vào `canvas` — không có đường cắt với nội
        // dung bên dưới và liền màu với dải header ghim phía trên (`--il-th-top`).
        gradientLayer.colors = [
            ILColors.templeHeaderTop.cgColor,
            ILColors.templeHeaderMid.cgColor,
            ILColors.canvas.cgColor
        ]
        gradientLayer.locations = [0.0, 0.58, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)

        // `radial-gradient(ellipse 60% 55% at 50% 45%, th-glow, transparent 100%)`: bán kính elip
        // = (endPoint − startPoint) × kích thước layer.
        glowLayer.type = .radial
        glowLayer.colors = [ILColors.templeHeaderGlow.cgColor, ILColors.goldGlowClear.cgColor]
        glowLayer.startPoint = CGPoint(x: 0.5, y: 0.45)
        glowLayer.endPoint = CGPoint(x: 1.1, y: 1.0)
        layer.insertSublayer(glowLayer, above: gradientLayer)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: Layout.topInset),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalInset),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalInset),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.bottomInset)
        ])
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILSutraDetailHeroView, _) in
            view.applyColorAppearanceChange()
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        glowLayer.frame = bounds
    }

    // `CAGradientLayer` màu là CGColor tĩnh, không tự đảo theo trait — resolve lại khi hệ thống
    // đổi light/dark (bộ `--il-th-*` có hai biến thể).
    private func applyColorAppearanceChange() {
        gradientLayer.colors = [
            ILColors.templeHeaderTop.resolvedColor(with: traitCollection).cgColor,
            ILColors.templeHeaderMid.resolvedColor(with: traitCollection).cgColor,
            ILColors.canvas.resolvedColor(with: traitCollection).cgColor
        ]
        glowLayer.colors = [
            ILColors.templeHeaderGlow.resolvedColor(with: traitCollection).cgColor,
            ILColors.goldGlowClear.cgColor
        ]
    }
}

/// Viền `hero-acc2` mỏng, nền `feat-glow` khi `isFilled` (chip "Có audio") — tự cập nhật màu viền
/// khi đổi light/dark.
private final class ILSutraDetailTagPillView: UIView {

    private let isFilled: Bool

    init(isFilled: Bool) {
        self.isFilled = isFilled
        super.init(frame: .zero)
        layer.cornerRadius = ILMetrics.radiusPill
        layer.borderWidth = 1
        applyColors()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILSutraDetailTagPillView, _) in
            view.applyColors()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func applyColors() {
        backgroundColor = isFilled ? ILColors.featGlow : .clear
        layer.borderColor = ILColors.heroAccentBorder.cgColor
    }
}
