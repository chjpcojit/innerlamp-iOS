//
//  ILLampCardView.swift
//  InnerLamp
//

import UIKit

/// 1 lamp in the garden grid: artwork on a warm tile, kind chip, title, dedication and the
/// remaining time. Fixed height (`ILMetrics.Lamp.cardHeight`).
final class ILLampCardView: UICollectionViewCell {

    static let reuseIdentifier = "ILLampCardView"

    private lazy var artArea: UIView = {
        let view = UIView()
        view.backgroundColor = ILColors.tint
        view.layer.cornerRadius = ILMetrics.radiusInput
        view.clipsToBounds = true
        return view
    }()

    private let artGlowLayer = CAGradientLayer()

    private lazy var artView: ILLampArtView = {
        let view = ILLampArtView(kind: .oil, showsRipple: true)
        return view
    }()

    private lazy var kindChip: ILLampCardChipView = {
        let chip = ILLampCardChipView()
        return chip
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.sectionTitle
        label.textColor = ILColors.ink
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var targetLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.bodySmall
        label.textColor = ILColors.inkTertiary
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var remainingLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.bodySmall
        label.textColor = ILColors.inkMuted
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with card: ILLampGardenStateModel.Card) {
        artView.kind = card.kind
        kindChip.text = card.kindName
        titleLabel.text = card.title
        targetLabel.text = card.target
        remainingLabel.text = card.remaining
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        artGlowLayer.frame = artArea.bounds
    }

    private func setupViews() {
        contentView.backgroundColor = ILColors.surface
        contentView.layer.cornerRadius = ILMetrics.radiusCardRegular
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = ILColors.gold.cgColor
        contentView.clipsToBounds = true

        artGlowLayer.type = .radial
        artGlowLayer.colors = [ILColors.goldGlow.cgColor, ILColors.goldGlowClear.cgColor]
        artGlowLayer.startPoint = CGPoint(x: 0.5, y: 0.62)
        artGlowLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        artArea.layer.addSublayer(artGlowLayer)

        [artArea, artView, kindChip, titleLabel, targetLabel, remainingLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        artArea.addSubview(artView)
        [artArea, kindChip, titleLabel, targetLabel, remainingLabel].forEach { contentView.addSubview($0) }
    }

    private func setupConstraints() {
        let size = ILMetrics.Lamp.cardArtSize
        NSLayoutConstraint.activate([
            artArea.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            artArea.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            artArea.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            artArea.heightAnchor.constraint(equalToConstant: ILMetrics.Lamp.cardArtAreaHeight),

            artView.centerXAnchor.constraint(equalTo: artArea.centerXAnchor),
            artView.bottomAnchor.constraint(equalTo: artArea.bottomAnchor, constant: -6),
            artView.widthAnchor.constraint(equalToConstant: size),
            artView.heightAnchor.constraint(equalToConstant: size * ILMetrics.Lamp.artHeightRatio),

            kindChip.topAnchor.constraint(equalTo: artArea.bottomAnchor, constant: 9),
            kindChip.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            kindChip.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -12),

            titleLabel.topAnchor.constraint(equalTo: kindChip.bottomAnchor, constant: 7),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

            targetLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            targetLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            targetLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            remainingLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            remainingLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            remainingLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
}

/// Small pill with the lamp kind name on a sunken background.
private final class ILLampCardChipView: UIView {

    var text: String = "" {
        didSet { label.text = text }
    }

    private lazy var label: UILabel = {
        let label = UILabel()
        label.font = ILTypography.caption
        label.textColor = ILColors.inkDim
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    init() {
        super.init(frame: .zero)
        backgroundColor = ILColors.tint2
        layer.cornerRadius = ILMetrics.radiusPill
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 3),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
