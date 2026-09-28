//
//  ILDeityMemorialDayCardView.swift
//  InnerLamp
//

import UIKit

/// Thẻ ngày vía gần nhất ở đầu màn chi tiết Phật & Bồ Tát — ô ngày/tháng âm (nền `--il-feat-glow`),
/// tên ngày vía + đếm ngược, link "Lịch lễ" bên phải. Riêng cho màn này nên ở `Scenes/Deity`.
final class ILDeityMemorialDayCardView: UIView {

    private enum Layout {
        static let tileWidth: CGFloat = 52
        static let tileRadius: CGFloat = 14
        static let tileVerticalInset: CGFloat = 8
        static let verticalInset: CGFloat = 14
        static let horizontalInset: CGFloat = 16
        static let spacing: CGFloat = 14
    }

    var onFestivalsTap: (() -> Void)?

    // MARK: - UI Elements
    private let tile = UIView()
    private let dayLabel = UILabel()
    private let monthLabel = UILabel()
    private let eventLabel = UILabel()
    private let countdownLabel = UILabel()
    private let festivalsButton = UIButton(type: .system)

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration
    func configure(with model: ILDeityMemorialDayModel, festivalsTitle: String) {
        dayLabel.text = model.dayText
        monthLabel.attributedText = ILTypography.makeEyebrow(text: model.monthText, color: ILColors.link)
        eventLabel.text = model.eventName
        countdownLabel.text = model.countdownText
        festivalsButton.setTitle(festivalsTitle, for: .normal)
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardRegular
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor

        tile.backgroundColor = ILColors.featGlow
        tile.layer.cornerRadius = Layout.tileRadius

        dayLabel.font = ILTypography.scriptureBodyLarge
        dayLabel.textColor = ILColors.link
        dayLabel.textAlignment = .center

        monthLabel.font = ILTypography.captionSmall
        monthLabel.textAlignment = .center
        monthLabel.adjustsFontSizeToFitWidth = true
        monthLabel.minimumScaleFactor = 0.7

        let tileStack = UIStackView(arrangedSubviews: [dayLabel, monthLabel])
        tileStack.axis = .vertical
        tileStack.alignment = .center
        tileStack.spacing = 0
        tileStack.translatesAutoresizingMaskIntoConstraints = false
        tile.addSubview(tileStack)

        eventLabel.font = ILTypography.bodyMedium
        eventLabel.textColor = ILColors.ink
        eventLabel.numberOfLines = 2

        countdownLabel.font = ILTypography.subhead
        countdownLabel.textColor = ILColors.inkTertiary
        countdownLabel.numberOfLines = 2

        let textStack = UIStackView(arrangedSubviews: [eventLabel, countdownLabel])
        textStack.axis = .vertical
        textStack.spacing = 3

        festivalsButton.titleLabel?.font = ILTypography.note
        festivalsButton.setTitleColor(ILColors.link, for: .normal)
        festivalsButton.addTarget(self, action: #selector(handleFestivalsTapped), for: .touchUpInside)
        festivalsButton.setContentHuggingPriority(.required, for: .horizontal)
        festivalsButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [tile, textStack, festivalsButton])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = Layout.spacing
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        NSLayoutConstraint.activate([
            tile.widthAnchor.constraint(equalToConstant: Layout.tileWidth),
            tileStack.topAnchor.constraint(equalTo: tile.topAnchor, constant: Layout.tileVerticalInset),
            tileStack.bottomAnchor.constraint(equalTo: tile.bottomAnchor, constant: -Layout.tileVerticalInset),
            tileStack.leadingAnchor.constraint(equalTo: tile.leadingAnchor, constant: 4),
            tileStack.trailingAnchor.constraint(equalTo: tile.trailingAnchor, constant: -4),

            row.topAnchor.constraint(equalTo: topAnchor, constant: Layout.verticalInset),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.verticalInset),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalInset),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalInset)
        ])

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILDeityMemorialDayCardView, _) in
            view.layer.borderColor = ILColors.border.cgColor
        }
    }

    @objc private func handleFestivalsTapped() {
        onFestivalsTap?()
    }
}
