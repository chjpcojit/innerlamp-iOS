//
//  ILSutrasCardView.swift
//  InnerLamp
//

import UIKit

/// 1 thẻ bộ kinh trong danh sách "Kinh sách": tên (Lora) + nguyên ngữ nghiêng + thời lượng, dòng
/// dịch giả · tông phái, và hàng nhãn (đã tải / có audio / mục đích). Riêng cho màn `Sutras`.
final class ILSutrasCardView: UIControl {

    // MARK: - Properties
    var onTap: (() -> Void)?

    // MARK: - UI Elements
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.serifCardTitle
        label.textColor = ILColors.ink
        label.numberOfLines = 0
        return label
    }()

    private lazy var originalLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.heroSubtitleItalic
        label.textColor = ILColors.inkTertiary
        label.numberOfLines = 0
        return label
    }()

    private lazy var durationLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.chip
        label.textColor = ILColors.ink
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private lazy var translatorLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.inkTertiary
        label.numberOfLines = 0
        return label
    }()

    private lazy var badgesView = ILChipFlowView(rowSpacing: ILMetrics.spaceSmall - 2, itemSpacing: ILMetrics.spaceSmall - 2)

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    func configure(with model: ILSutrasItemModel) {
        nameLabel.text = model.name
        originalLabel.text = model.originalName
        durationLabel.text = model.durationText
        translatorLabel.text = model.translatorLine
        translatorLabel.isHidden = model.translatorLine.isEmpty
        durationLabel.isHidden = model.durationText.isEmpty

        var badges: [UIView] = []
        if model.isDownloaded {
            badges.append(Self.makeBadge(
                text: "sutras.badge.downloaded".localized,
                textColor: ILColors.greenText, fill: ILColors.greenTint, border: nil
            ))
        }
        if model.hasAudio {
            badges.append(Self.makeBadge(
                text: "sutras.badge.audio".localized,
                textColor: ILColors.link, fill: ILColors.featGlow, border: nil
            ))
        }
        badges += model.purposeLabels.map {
            Self.makeBadge(text: $0, textColor: ILColors.inkDim, fill: .clear, border: ILColors.borderStrong)
        }
        badgesView.setItems(badges)
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardSmall
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor

        let titleStack = UIStackView(arrangedSubviews: [nameLabel, originalLabel])
        titleStack.axis = .vertical
        titleStack.spacing = 3

        let topRow = UIStackView(arrangedSubviews: [titleStack, durationLabel])
        topRow.axis = .horizontal
        topRow.alignment = .top
        topRow.spacing = ILMetrics.rowSpacing

        let content = UIStackView(arrangedSubviews: [topRow, translatorLabel, badgesView])
        content.axis = .vertical
        content.spacing = ILMetrics.spaceSmall
        content.setCustomSpacing(ILMetrics.rowSpacing, after: translatorLabel)
        content.isUserInteractionEnabled = false
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: topAnchor, constant: ILMetrics.spaceMedium),
            content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.spaceStandard),
            content.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.spaceStandard),
            content.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -ILMetrics.spaceMedium)
        ])

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILSutrasCardView, _) in
            view.layer.borderColor = ILColors.border.cgColor
        }
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.7 : 1 }
    }

    @objc private func handleTap() {
        onTap?()
    }

    // MARK: - Badge
    private static func makeBadge(text: String, textColor: UIColor, fill: UIColor, border: UIColor?) -> UIView {
        let label = UILabel()
        label.text = text
        label.font = ILTypography.captionMedium
        label.textColor = textColor
        label.translatesAutoresizingMaskIntoConstraints = false

        let pill = UIView()
        pill.backgroundColor = fill
        pill.layer.cornerRadius = ILMetrics.radiusPill
        if let border {
            pill.layer.borderWidth = 1
            pill.layer.borderColor = border.cgColor
        }
        pill.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: pill.topAnchor, constant: 3),
            label.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -3),
            label.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 9),
            label.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -9)
        ])
        return pill
    }
}
