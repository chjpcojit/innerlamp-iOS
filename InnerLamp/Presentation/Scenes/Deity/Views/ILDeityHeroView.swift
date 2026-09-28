//
//  ILDeityHeroView.swift
//  InnerLamp
//

import UIKit

/// Hero 420pt full-bleed của màn chi tiết Phật & Bồ Tát — khớp `isBuddha` trong design handoff:
/// nền `--il-sunk2` (chỗ đặt ảnh tôn tượng), lớp phủ `--il-hero-ov` tan dần xuống đáy, hai chip
/// (loại · cõi tịnh độ), danh xưng Lora 28 và Phạn ngữ nghiêng.
///
/// Chưa có ảnh tôn tượng thật nên danh xưng chữ Hán được in chìm kèm quầng sáng vàng thay chỗ
/// ảnh. Header (nút ‹) không nằm ở đây mà là `ILNavBar` đè lên trên — xem `ILDeityViewController`.
final class ILDeityHeroView: UIView {

    private enum Layout {
        static let height: CGFloat = 420
        static let horizontalInset: CGFloat = 20
        static let bottomInset: CGFloat = 30
        static let glowDiameter: CGFloat = 360
        static let watermarkFontSize: CGFloat = 96
        static let chipVerticalInset: CGFloat = 4
        static let chipHorizontalInset: CGFloat = 10
    }

    // MARK: - UI Elements
    private let glowLayer = CAGradientLayer()
    private let overlayLayer = CAGradientLayer()

    private let watermarkLabel = UILabel()

    private let kindChip = UIView()
    private let kindLabel = UILabel()
    private let realmChip = UIView()
    private let realmLabel = UILabel()

    private let nameLabel = UILabel()
    private let sanskritLabel = UILabel()
    private let contentStack = UIStackView()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration
    func configure(kindLabel: String, realm: String, name: String, sanskrit: String, watermark: String) {
        self.kindLabel.text = kindLabel
        realmLabel.text = realm
        realmChip.isHidden = realm.isEmpty

        nameLabel.attributedText = ILTypography.makeParagraph(
            text: name,
            font: ILTypography.imageHeroTitle,
            color: ILColors.heroInk,
            cssLineHeight: 1.2
        )
        sanskritLabel.text = sanskrit
        sanskritLabel.isHidden = sanskrit.isEmpty
        watermarkLabel.text = watermark
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = ILColors.sunk2
        clipsToBounds = true

        // Quầng sáng vàng thay chỗ ảnh tôn tượng.
        glowLayer.type = .radial
        glowLayer.colors = [ILColors.featGlow.cgColor, ILColors.featGlowClear.cgColor]
        glowLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        glowLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(glowLayer)

        watermarkLabel.font = ILTypography.lora(size: Layout.watermarkFontSize)
        watermarkLabel.textColor = ILColors.heroInk.withAlphaComponent(0.07)
        watermarkLabel.textAlignment = .center
        watermarkLabel.adjustsFontSizeToFitWidth = true
        watermarkLabel.minimumScaleFactor = 0.4
        watermarkLabel.isAccessibilityElement = false
        watermarkLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(watermarkLabel)

        // Lớp phủ `--il-hero-ov`: 3 chặng, đậm dần xuống đáy để chữ đọc được trên ảnh.
        overlayLayer.colors = [
            ILColors.heroOverlayStart.cgColor,
            ILColors.heroOverlayMid.cgColor,
            ILColors.heroOverlayEnd.cgColor
        ]
        overlayLayer.locations = [0.0, 0.58, 1.0]
        overlayLayer.startPoint = CGPoint(x: 0.5, y: 0)
        overlayLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.addSublayer(overlayLayer)

        configureChip(kindChip, label: kindLabel, textColor: ILColors.heroAccent)
        configureChip(realmChip, label: realmLabel, textColor: ILColors.heroInk)
        realmLabel.lineBreakMode = .byTruncatingTail
        realmChip.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        realmLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let chipsRow = UIStackView(arrangedSubviews: [kindChip, realmChip, UIView()])
        chipsRow.axis = .horizontal
        chipsRow.spacing = 6
        chipsRow.alignment = .center

        nameLabel.numberOfLines = 0

        sanskritLabel.font = ILTypography.heroSubtitleItalic
        sanskritLabel.textColor = ILColors.heroInk.withAlphaComponent(0.8)
        sanskritLabel.numberOfLines = 0

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 0
        contentStack.isUserInteractionEnabled = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(chipsRow)
        contentStack.setCustomSpacing(12, after: chipsRow)
        contentStack.addArrangedSubview(nameLabel)
        contentStack.setCustomSpacing(6, after: nameLabel)
        contentStack.addArrangedSubview(sanskritLabel)
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Layout.height),

            watermarkLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            watermarkLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -Layout.height * 0.12),
            watermarkLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: Layout.horizontalInset),
            watermarkLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -Layout.horizontalInset),

            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalInset),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalInset),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.bottomInset)
        ])

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILDeityHeroView, _) in
            view.applyColorAppearanceChange()
        }
    }

    private func configureChip(_ chip: UIView, label: UILabel, textColor: UIColor) {
        chip.layer.cornerRadius = ILMetrics.radiusPill
        chip.layer.borderWidth = 1
        chip.layer.borderColor = ILColors.heroAccentBorder.cgColor

        label.font = ILTypography.captionMedium
        label.textColor = textColor
        label.translatesAutoresizingMaskIntoConstraints = false
        chip.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: chip.topAnchor, constant: Layout.chipVerticalInset),
            label.bottomAnchor.constraint(equalTo: chip.bottomAnchor, constant: -Layout.chipVerticalInset),
            label.leadingAnchor.constraint(equalTo: chip.leadingAnchor, constant: Layout.chipHorizontalInset),
            label.trailingAnchor.constraint(equalTo: chip.trailingAnchor, constant: -Layout.chipHorizontalInset)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        overlayLayer.frame = bounds
        glowLayer.frame = CGRect(
            x: bounds.midX - Layout.glowDiameter / 2,
            y: bounds.height * 0.30 - Layout.glowDiameter / 2,
            width: Layout.glowDiameter,
            height: Layout.glowDiameter
        )
        // Chip bo tròn theo chiều cao thật (999 bị UIKit kẹp nhưng giữ rõ ý đồ).
        kindChip.layer.cornerRadius = kindChip.bounds.height / 2
        realmChip.layer.cornerRadius = realmChip.bounds.height / 2
    }

    // `CAGradientLayer` / `layer.borderColor` là CGColor tĩnh, không tự đảo theo trait — resolve
    // lại khi hệ thống đổi light/dark (bộ `--il-hero-*` có hai biến thể).
    private func applyColorAppearanceChange() {
        overlayLayer.colors = [
            ILColors.heroOverlayStart.resolvedColor(with: traitCollection).cgColor,
            ILColors.heroOverlayMid.resolvedColor(with: traitCollection).cgColor,
            ILColors.heroOverlayEnd.resolvedColor(with: traitCollection).cgColor
        ]
        glowLayer.colors = [
            ILColors.featGlow.resolvedColor(with: traitCollection).cgColor,
            ILColors.featGlowClear.cgColor
        ]
        let chipBorder = ILColors.heroAccentBorder.resolvedColor(with: traitCollection).cgColor
        kindChip.layer.borderColor = chipBorder
        realmChip.layer.borderColor = chipBorder
    }
}
