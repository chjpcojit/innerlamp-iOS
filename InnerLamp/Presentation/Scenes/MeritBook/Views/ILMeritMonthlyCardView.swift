//
//  ILMeritMonthlyCardView.swift
//  InnerLamp
//

import UIKit

/// "Hộ trì hằng tháng": an active card (calendar tile, title, subtitle, "Dừng" pill) or a dashed
/// note when the recurring offering is off.
final class ILMeritMonthlyCardView: UIView {

    var onStop: (() -> Void)?

    private lazy var activeCard = ILMeritCardView()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.sectionTitle
        label.textColor = ILColors.ink
        label.numberOfLines = 0
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.note
        label.textColor = ILColors.inkTertiary
        label.numberOfLines = 0
        return label
    }()

    private lazy var emptyCard = ILMeritDashedNoteView(text: "meritBook.monthly.off".localized)

    init() {
        super.init(frame: .zero)

        let tile = UIView()
        tile.backgroundColor = ILColors.Tone.green.tintBackground
        tile.layer.cornerRadius = ILMetrics.radiusIconTile
        let glyph = UIImageView(image: ILIcons.rowCalendar)
        glyph.tintColor = ILColors.Tone.green.accentColor
        glyph.contentMode = .scaleAspectFit
        glyph.translatesAutoresizingMaskIntoConstraints = false
        tile.addSubview(glyph)

        let texts = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        texts.axis = .vertical
        texts.spacing = 3

        var stopConfig = UIButton.Configuration.plain()
        stopConfig.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        stopConfig.baseForegroundColor = ILColors.ink
        stopConfig.attributedTitle = AttributedString(
            "meritBook.monthly.stop".localized,
            attributes: AttributeContainer([.font: ILTypography.note])
        )
        let stop = UIButton(configuration: stopConfig)
        stop.layer.cornerRadius = 18
        stop.layer.borderWidth = 1
        stop.layer.borderColor = ILColors.borderStrong.resolvedColor(with: traitCollection).cgColor
        stop.setContentHuggingPriority(.required, for: .horizontal)
        stop.setContentCompressionResistancePriority(.required, for: .horizontal)
        stop.addTarget(self, action: #selector(handleStop), for: .touchUpInside)

        let row = UIStackView(arrangedSubviews: [tile, texts, stop])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 14
        activeCard.embed(row, insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))

        NSLayoutConstraint.activate([
            tile.widthAnchor.constraint(equalToConstant: ILMetrics.iconTileSize),
            tile.heightAnchor.constraint(equalToConstant: ILMetrics.iconTileSize),
            glyph.topAnchor.constraint(equalTo: tile.topAnchor),
            glyph.bottomAnchor.constraint(equalTo: tile.bottomAnchor),
            glyph.leadingAnchor.constraint(equalTo: tile.leadingAnchor),
            glyph.trailingAnchor.constraint(equalTo: tile.trailingAnchor)
        ])

        [activeCard, emptyCard].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
            NSLayoutConstraint.activate([
                $0.topAnchor.constraint(equalTo: topAnchor),
                $0.bottomAnchor.constraint(equalTo: bottomAnchor),
                $0.leadingAnchor.constraint(equalTo: leadingAnchor),
                $0.trailingAnchor.constraint(equalTo: trailingAnchor)
            ])
        }
        configure(monthly: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(monthly: ILMeritBookStateModel.Monthly?) {
        activeCard.isHidden = monthly == nil
        emptyCard.isHidden = monthly != nil
        titleLabel.text = monthly?.title
        subtitleLabel.text = monthly?.subtitle
    }

    @objc private func handleStop() {
        onStop?()
    }
}

/// Dashed-border note card ("Chưa bật hộ trì hằng tháng…").
final class ILMeritDashedNoteView: UIView {

    private let dashLayer = CAShapeLayer()

    init(text: String) {
        super.init(frame: .zero)
        let label = UILabel()
        label.font = ILTypography.note
        label.textColor = ILColors.inkTertiary
        label.numberOfLines = 0
        label.text = text
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])

        dashLayer.fillColor = nil
        dashLayer.lineWidth = 1
        dashLayer.lineDashPattern = [4, 3]
        layer.addSublayer(dashLayer)
        applyColors()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILMeritDashedNoteView, _) in
            view.applyColors()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        dashLayer.frame = bounds
        dashLayer.path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5),
            cornerRadius: ILMetrics.radiusCardRegular
        ).cgPath
    }

    private func applyColors() {
        dashLayer.strokeColor = ILColors.borderStrong.resolvedColor(with: traitCollection).cgColor
    }
}
