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
    private lazy var tile: UIView = {
        let v = UIView()
        v.backgroundColor = ILColors.featGlow
        v.layer.cornerRadius = Layout.tileRadius
        return v
    }()
    private lazy var dayLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.scriptureBodyLarge
        v.textColor = ILColors.link
        v.textAlignment = .center
        return v
    }()
    private lazy var monthLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.captionSmall
        v.textAlignment = .center
        v.adjustsFontSizeToFitWidth = true
        v.minimumScaleFactor = 0.7
        return v
    }()
    private lazy var eventLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.bodyMedium
        v.textColor = ILColors.ink
        v.numberOfLines = 2
        return v
    }()
    private lazy var countdownLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.subhead
        v.textColor = ILColors.inkTertiary
        v.numberOfLines = 2
        return v
    }()
    private lazy var festivalsButton: UIButton = {
        let v = UIButton(type: .system)
        v.titleLabel?.font = ILTypography.note
        v.setTitleColor(ILColors.link, for: .normal)
        v.setContentHuggingPriority(.required, for: .horizontal)
        v.setContentCompressionResistancePriority(.required, for: .horizontal)
        return v
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

        let tileStack = UIStackView(arrangedSubviews: [dayLabel, monthLabel])
        tileStack.axis = .vertical
        tileStack.alignment = .center
        tileStack.spacing = 0
        tileStack.translatesAutoresizingMaskIntoConstraints = false
        tile.addSubview(tileStack)

        let textStack = UIStackView(arrangedSubviews: [eventLabel, countdownLabel])
        textStack.axis = .vertical
        textStack.spacing = 3

        festivalsButton.addTarget(self, action: #selector(handleFestivalsTapped), for: .touchUpInside)

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
