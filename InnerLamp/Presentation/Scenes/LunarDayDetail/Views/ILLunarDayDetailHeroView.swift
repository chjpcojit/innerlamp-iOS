//
//  ILLunarDayDetailHeroView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 27/9/26.
//

import UIKit

/// Bìa hero màn "Chi tiết ngày âm" — khớp `isLunar` trong design handoff: nền gradient
/// `--il-sunk2 → --il-tint → --il-canvas` (tan dần vào nền trang, đổi theo light/dark), ngày âm
/// lớn 72px, tháng/năm âm, ngày dương + pill "loại ngày" và dòng lời khuyên ở đáy.
///
/// Header (nút ‹) không nằm ở đây mà là `ILNavBar` trong suốt đè lên trên — xem
/// `ILLunarDayDetailViewController`.
final class ILLunarDayDetailHeroView: UIView {

    private enum Layout {
        static let height: CGFloat = 380
        static let horizontalInset: CGFloat = 20
        static let bottomInset: CGFloat = 14
    }

    // MARK: - UI Elements
    private let gradientLayer = CAGradientLayer()

    private let eyebrowDot = UIView()
    private let eyebrowLabel = UILabel()

    private let dayLabel = UILabel()
    private let monthLabel = UILabel()
    private let yearLabel = UILabel()

    private let solarLabel = UILabel()
    private let typePill = UIView()
    private let typeDot = UIView()
    private let typeLabel = UILabel()

    private let adviceLabel = UILabel()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration
    func configure(
        eyebrowText: String,
        day: String,
        month: String,
        year: String,
        solar: String,
        typeTone: ILLunarDayDetailTypeTone,
        typeText: String,
        adviceText: String
    ) {
        eyebrowLabel.attributedText = ILTypography.makeAttributedString(
            text: eyebrowText,
            font: ILTypography.eyebrowSmall,
            color: ILColors.featAccent,
            letterSpacingEm: 0.18
        )
        dayLabel.text = day
        monthLabel.text = month
        yearLabel.text = year
        solarLabel.text = solar
        typeDot.backgroundColor = dotColor(for: typeTone)
        typeLabel.text = typeText
        adviceLabel.text = adviceText
    }

    private func dotColor(for tone: ILLunarDayDetailTypeTone) -> UIColor {
        switch tone {
        case .gold: return ILColors.goldBright
        case .auspicious: return ILColors.auspicious
        case .inauspicious: return ILColors.inauspicious
        }
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = true

        gradientLayer.colors = [ILColors.sunk2.cgColor, ILColors.tint.cgColor, ILColors.canvas.cgColor]
        gradientLayer.locations = [0.0, 0.55, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)

        // Eyebrow: chấm vàng + "ÂM LỊCH".
        eyebrowDot.backgroundColor = ILColors.featAccent
        eyebrowDot.layer.cornerRadius = 7
        eyebrowDot.layer.borderWidth = 1
        eyebrowDot.layer.borderColor = ILColors.featAccent.withAlphaComponent(0.5).cgColor
        eyebrowDot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            eyebrowDot.widthAnchor.constraint(equalToConstant: 14),
            eyebrowDot.heightAnchor.constraint(equalToConstant: 14)
        ])

        eyebrowLabel.numberOfLines = 1

        let eyebrowRow = UIStackView(arrangedSubviews: [eyebrowDot, eyebrowLabel])
        eyebrowRow.axis = .horizontal
        eyebrowRow.spacing = 7
        eyebrowRow.alignment = .center

        dayLabel.font = ILTypography.lunarHeroDay
        dayLabel.textColor = ILColors.ink
        dayLabel.numberOfLines = 1

        monthLabel.font = ILTypography.scriptureBody
        monthLabel.textColor = ILColors.inkSecondary
        monthLabel.numberOfLines = 1

        yearLabel.font = ILTypography.bodyCompact
        yearLabel.textColor = ILColors.inkTertiary
        yearLabel.numberOfLines = 1

        let monthYearStack = UIStackView(arrangedSubviews: [monthLabel, yearLabel])
        monthYearStack.axis = .vertical
        monthYearStack.spacing = 2
        monthYearStack.alignment = .leading

        let dayRow = UIStackView(arrangedSubviews: [dayLabel, monthYearStack])
        dayRow.axis = .horizontal
        dayRow.alignment = .bottom
        dayRow.spacing = 14

        solarLabel.font = ILTypography.sectionTitle
        solarLabel.textColor = ILColors.ink
        solarLabel.numberOfLines = 1
        solarLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        typeDot.layer.cornerRadius = 3.5
        typeDot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            typeDot.widthAnchor.constraint(equalToConstant: 7),
            typeDot.heightAnchor.constraint(equalToConstant: 7)
        ])

        typeLabel.font = ILTypography.subheadMedium
        typeLabel.textColor = ILColors.ink
        typeLabel.numberOfLines = 1

        let pillStack = UIStackView(arrangedSubviews: [typeDot, typeLabel])
        pillStack.axis = .horizontal
        pillStack.spacing = 7
        pillStack.alignment = .center
        pillStack.translatesAutoresizingMaskIntoConstraints = false
        pillStack.isUserInteractionEnabled = false

        typePill.backgroundColor = ILColors.surface
        typePill.layer.cornerRadius = ILMetrics.radiusPill
        typePill.layer.borderWidth = 1
        typePill.layer.borderColor = ILColors.border.cgColor
        typePill.addSubview(pillStack)
        NSLayoutConstraint.activate([
            pillStack.topAnchor.constraint(equalTo: typePill.topAnchor, constant: 6),
            pillStack.bottomAnchor.constraint(equalTo: typePill.bottomAnchor, constant: -6),
            pillStack.leadingAnchor.constraint(equalTo: typePill.leadingAnchor, constant: 12),
            pillStack.trailingAnchor.constraint(equalTo: typePill.trailingAnchor, constant: -12)
        ])

        let solarRow = UIStackView(arrangedSubviews: [solarLabel, typePill])
        solarRow.axis = .horizontal
        solarRow.alignment = .center
        solarRow.distribution = .fill

        adviceLabel.font = ILTypography.bodySmall
        adviceLabel.textColor = ILColors.inkTertiary
        adviceLabel.numberOfLines = 0

        let contentStack = UIStackView(arrangedSubviews: [eyebrowRow, dayRow, solarRow, adviceLabel])
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 10
        contentStack.setCustomSpacing(14, after: dayRow)
        contentStack.setCustomSpacing(6, after: solarRow)
        contentStack.isUserInteractionEnabled = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Layout.height),

            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalInset),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalInset),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.bottomInset)
        ])
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILLunarDayDetailHeroView, _) in
            view.applyColorAppearanceChange()
        }
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    // `CAGradientLayer` màu là CGColor tĩnh, không tự đảo theo trait — resolve lại khi hệ thống
    // đổi light/dark (`--il-sunk2`/`--il-tint` có hai biến thể).
    private func applyColorAppearanceChange() {
        gradientLayer.colors = [
            ILColors.sunk2.resolvedColor(with: traitCollection).cgColor,
            ILColors.tint.resolvedColor(with: traitCollection).cgColor,
            ILColors.canvas.resolvedColor(with: traitCollection).cgColor
        ]
        eyebrowDot.layer.borderColor = ILColors.featAccent.withAlphaComponent(0.5).cgColor
        typePill.layer.borderColor = ILColors.border.cgColor
    }
}
