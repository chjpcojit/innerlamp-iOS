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
/// Khi server trả ảnh (`GET /v1/calendar/image`), ảnh phủ kín hero phía trên gradient (gradient vẫn là
/// placeholder khi chưa có ảnh/ảnh lỗi) và một lớp phủ mờ dần về màu nền trang giữ cho chữ ở đáy hero
/// đọc được; dòng ghi công tác giả/giấy phép nằm dưới cùng.
///
/// Ảnh = `imageView` của `ILStretchyHeaderView`: ghim trên cùng và co giãn khi kéo xuống; gradient
/// placeholder nằm ở `backgroundView`, lớp phủ + chữ ở `contentView`. `imageHeight` là 0 khi chưa có ảnh.
///
/// Header (nút ‹) không nằm ở đây mà là `ILNavBar` trong suốt đè lên trên — xem
/// `ILLunarDayDetailViewController`.
final class ILLunarDayDetailHeroView: ILStretchyHeaderView {

    private enum Layout {
        static let height: CGFloat = 380
        static let horizontalInset: CGFloat = 20
        static let bottomInset: CGFloat = 14
    }

    // MARK: - UI Elements
    private let gradientLayer = CAGradientLayer()

    private let scrimLayer = CAGradientLayer()
    private lazy var scrimView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        view.isHidden = true
        return view
    }()

    private var currentImageURL: String?

    private lazy var creditLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.caption
        label.textColor = ILColors.inkTertiary
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    private lazy var eyebrowDot: UIView = {
        let view = UIView()
        view.backgroundColor = ILColors.featAccent
        view.layer.cornerRadius = 7
        view.layer.borderWidth = 1
        view.layer.borderColor = ILColors.featAccent.withAlphaComponent(0.5).cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var eyebrowLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        return label
    }()

    private lazy var dayLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.lunarHeroDay
        label.textColor = ILColors.ink
        label.numberOfLines = 1
        return label
    }()

    private lazy var monthLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.scriptureBody
        label.textColor = ILColors.inkSecondary
        label.numberOfLines = 1
        return label
    }()

    private lazy var yearLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.bodyCompact
        label.textColor = ILColors.inkTertiary
        label.numberOfLines = 1
        return label
    }()

    private lazy var solarLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.sectionTitle
        label.textColor = ILColors.ink
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private lazy var typePill: UIView = {
        let view = UIView()
        view.backgroundColor = ILColors.surface
        view.layer.cornerRadius = ILMetrics.radiusPill
        view.layer.borderWidth = 1
        view.layer.borderColor = ILColors.border.cgColor
        return view
    }()

    private lazy var typeDot: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 3.5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var typeLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subheadMedium
        label.textColor = ILColors.ink
        label.numberOfLines = 1
        return label
    }()

    private lazy var adviceLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.bodySmall
        label.textColor = ILColors.inkTertiary
        label.numberOfLines = 0
        return label
    }()

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
        adviceText: String,
        imageURL: String?,
        creditText: String
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

        // `configure` runs on every state emission (verse / image loads); `setImage` clears the
        // bitmap and refetches, so only call it when the URL actually changed.
        if imageURL != currentImageURL {
            currentImageURL = imageURL
            imageView.setImage(urlString: imageURL)
            imageHeight = imageURL == nil ? 0 : Layout.height
            scrimView.isHidden = imageURL == nil
        }
        creditLabel.text = creditText
        creditLabel.isHidden = creditText.isEmpty
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
        // Ảnh của ngày; nền trong suốt để gradient phía sau làm placeholder.
        imageView.backgroundColor = .clear

        gradientLayer.colors = [ILColors.sunk2.cgColor, ILColors.tint.cgColor, ILColors.canvas.cgColor]
        gradientLayer.locations = [0.0, 0.55, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        backgroundView.layer.insertSublayer(gradientLayer, at: 0)

        scrimLayer.locations = [0.0, 0.35, 0.6, 1.0]
        scrimLayer.startPoint = CGPoint(x: 0.5, y: 0)
        scrimLayer.endPoint = CGPoint(x: 0.5, y: 1)
        scrimView.layer.addSublayer(scrimLayer)
        applyScrimColors()
        contentView.addSubview(scrimView)
        NSLayoutConstraint.activate([
            scrimView.topAnchor.constraint(equalTo: topAnchor),
            scrimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrimView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrimView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Eyebrow: chấm vàng + "ÂM LỊCH".
        NSLayoutConstraint.activate([
            eyebrowDot.widthAnchor.constraint(equalToConstant: 14),
            eyebrowDot.heightAnchor.constraint(equalToConstant: 14)
        ])

        let eyebrowRow = UIStackView(arrangedSubviews: [eyebrowDot, eyebrowLabel])
        eyebrowRow.axis = .horizontal
        eyebrowRow.spacing = 7
        eyebrowRow.alignment = .center

        let monthYearStack = UIStackView(arrangedSubviews: [monthLabel, yearLabel])
        monthYearStack.axis = .vertical
        monthYearStack.spacing = 2
        monthYearStack.alignment = .leading

        let dayRow = UIStackView(arrangedSubviews: [dayLabel, monthYearStack])
        dayRow.axis = .horizontal
        dayRow.alignment = .bottom
        dayRow.spacing = 14

        NSLayoutConstraint.activate([
            typeDot.widthAnchor.constraint(equalToConstant: 7),
            typeDot.heightAnchor.constraint(equalToConstant: 7)
        ])

        let pillStack = UIStackView(arrangedSubviews: [typeDot, typeLabel])
        pillStack.axis = .horizontal
        pillStack.spacing = 7
        pillStack.alignment = .center
        pillStack.translatesAutoresizingMaskIntoConstraints = false
        pillStack.isUserInteractionEnabled = false

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

        let contentStack = UIStackView(arrangedSubviews: [eyebrowRow, dayRow, solarRow, adviceLabel, creditLabel])
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 10
        contentStack.setCustomSpacing(14, after: dayRow)
        contentStack.setCustomSpacing(6, after: solarRow)
        contentStack.setCustomSpacing(8, after: adviceLabel)
        contentStack.isUserInteractionEnabled = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(contentStack)

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
        scrimLayer.frame = bounds
    }

    /// Trong suốt ở đỉnh (ảnh lộ rõ) → màu nền trang ở đáy (chữ đọc được). `CGColor` tĩnh nên phải
    /// resolve theo trait hiện tại.
    private func applyScrimColors() {
        let canvas = ILColors.canvas.resolvedColor(with: traitCollection)
        scrimLayer.colors = [0.0, 0.55, 0.92, 1.0].map { canvas.withAlphaComponent($0).cgColor }
    }

    // `CAGradientLayer` màu là CGColor tĩnh, không tự đảo theo trait — resolve lại khi hệ thống
    // đổi light/dark (`--il-sunk2`/`--il-tint` có hai biến thể).
    private func applyColorAppearanceChange() {
        gradientLayer.colors = [
            ILColors.sunk2.resolvedColor(with: traitCollection).cgColor,
            ILColors.tint.resolvedColor(with: traitCollection).cgColor,
            ILColors.canvas.resolvedColor(with: traitCollection).cgColor
        ]
        applyScrimColors()
        eyebrowDot.layer.borderColor = ILColors.featAccent.withAlphaComponent(0.5).cgColor
        typePill.layer.borderColor = ILColors.border.cgColor
    }
}
