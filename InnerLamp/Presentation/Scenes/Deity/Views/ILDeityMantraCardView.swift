//
//  ILDeityMantraCardView.swift
//  InnerLamp
//

import UIKit

/// 1 thẻ "Thần chú & danh hiệu" — nền `--il-feat-bg` (gradient theme-aware) + quầng sáng góc
/// trên phải, nhãn caps màu nhấn, câu niệm Lora 19, Phạn ngữ nghiêng, ghi chú, và hai nút
/// "Trì niệm với tràng hạt" (vàng) / "Chia sẻ" (viền). Riêng cho màn chi tiết Phật & Bồ Tát.
final class ILDeityMantraCardView: UIView {

    private enum Layout {
        static let inset: CGFloat = 18
        static let buttonHeight: CGFloat = 38
    }

    var onChantTap: (() -> Void)?
    var onShareTap: (() -> Void)?

    // MARK: - UI Elements
    // Decorative layers live in their own clipped container so the card itself (which holds the
    // text and buttons) never needs `clipsToBounds`, avoiding stale masked-layer rendering.
    private let backdropLayer = CALayer()
    private let gradientLayer = CAGradientLayer()
    private let glowLayer = CAGradientLayer()

    private lazy var eyebrowLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.eyebrowSmall
        return v
    }()
    private lazy var textLabel: UILabel = {
        let v = UILabel()
        v.numberOfLines = 0
        return v
    }()
    private lazy var sanskritLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.heroSubtitleItalic
        v.textColor = ILColors.templeHeaderSub
        v.numberOfLines = 0
        return v
    }()
    private lazy var noteLabel: UILabel = {
        let v = UILabel()
        v.numberOfLines = 0
        return v
    }()
    private lazy var chantButton: ILDeityPillButton = {
        let v = ILDeityPillButton(textColor: ILColors.inkOnGold)
        v.backgroundColor = ILColors.goldBright
        return v
    }()
    private lazy var shareButton: ILDeityPillButton = {
        let v = ILDeityPillButton(textColor: ILColors.templeHeaderInk)
        v.layer.borderWidth = 1
        return v
    }()

    // MARK: - Initializer
    init(model: ILDeityMantraModel, chantTitle: String, shareTitle: String) {
        super.init(frame: .zero)
        setupViews()
        configure(model: model, chantTitle: chantTitle, shareTitle: shareTitle)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration
    private func configure(model: ILDeityMantraModel, chantTitle: String, shareTitle: String) {
        eyebrowLabel.attributedText = ILTypography.makeEyebrow(text: model.label, color: ILColors.heroAccent)
        textLabel.attributedText = ILTypography.makeParagraph(
            text: model.text,
            font: ILTypography.heroCardTitle,
            color: ILColors.templeHeaderInk,
            cssLineHeight: 1.45
        )
        sanskritLabel.text = model.sanskrit
        sanskritLabel.isHidden = model.sanskrit.isEmpty
        noteLabel.attributedText = ILTypography.makeParagraph(
            text: model.note,
            font: ILTypography.note,
            color: ILColors.templeHeaderSub,
            cssLineHeight: 1.6
        )
        noteLabel.isHidden = model.note.isEmpty
        chantButton.title = chantTitle
        shareButton.title = shareTitle
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = ILMetrics.radiusCardRegular
        layer.borderWidth = 1
        backdropLayer.cornerRadius = ILMetrics.radiusCardRegular
        backdropLayer.masksToBounds = true
        layer.insertSublayer(backdropLayer, at: 0)

        // `linear-gradient(140deg, start, end)`.
        gradientLayer.startPoint = CGPoint(x: 0.18, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.82, y: 1)
        backdropLayer.addSublayer(gradientLayer)

        // `radial-gradient(ellipse 70% 60% at 85% 20%, glow, transparent)`.
        glowLayer.type = .radial
        glowLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        glowLayer.endPoint = CGPoint(x: 1, y: 1)
        backdropLayer.addSublayer(glowLayer)

        chantButton.addTarget(self, action: #selector(handleChantTapped), for: .touchUpInside)

        shareButton.addTarget(self, action: #selector(handleShareTapped), for: .touchUpInside)

        let buttonsRow = UIStackView(arrangedSubviews: [chantButton, shareButton, UIView()])
        buttonsRow.axis = .horizontal
        buttonsRow.spacing = ILMetrics.spaceSmall
        buttonsRow.alignment = .center

        let stack = UIStackView(arrangedSubviews: [eyebrowLabel, textLabel, sanskritLabel, noteLabel, buttonsRow])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 0
        stack.setCustomSpacing(8, after: eyebrowLabel)
        stack.setCustomSpacing(6, after: textLabel)
        stack.setCustomSpacing(10, after: sanskritLabel)
        stack.setCustomSpacing(14, after: noteLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: Layout.inset),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.inset),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.inset),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.inset),
            chantButton.heightAnchor.constraint(equalToConstant: Layout.buttonHeight),
            shareButton.heightAnchor.constraint(equalToConstant: Layout.buttonHeight)
        ])

        applyColorAppearanceChange()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILDeityMantraCardView, _) in
            view.applyColorAppearanceChange()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        backdropLayer.frame = bounds
        gradientLayer.frame = backdropLayer.bounds
        glowLayer.frame = CGRect(
            x: bounds.width * 0.85 - bounds.width * 0.7,
            y: bounds.height * 0.2 - bounds.height * 0.6,
            width: bounds.width * 1.4,
            height: bounds.height * 1.2
        )
    }

    // CGColor tĩnh không tự đảo theo trait — resolve lại khi đổi light/dark (bộ `--il-feat-*`).
    private func applyColorAppearanceChange() {
        gradientLayer.colors = [
            ILColors.featBackgroundStart.resolvedColor(with: traitCollection).cgColor,
            ILColors.featBackgroundEnd.resolvedColor(with: traitCollection).cgColor
        ]
        glowLayer.colors = [
            ILColors.featGlow.resolvedColor(with: traitCollection).cgColor,
            ILColors.featGlowClear.cgColor
        ]
        layer.borderColor = ILColors.featBorder.resolvedColor(with: traitCollection).cgColor
        shareButton.layer.borderColor = ILColors.heroAccentBorder.resolvedColor(with: traitCollection).cgColor
    }

    // MARK: - Actions
    @objc private func handleChantTapped() {
        onChantTap?()
    }

    @objc private func handleShareTapped() {
        onShareTap?()
    }
}

/// Nút viên thuốc dựng từ `UIControl` + `UILabel` (như `ILButton`) — không dùng
/// `UIButton.Configuration`, vì chữ của nó có thể biến mất sau khi màn được push/pop.
private final class ILDeityPillButton: UIControl {

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.chip
        label.textAlignment = .center
        label.isUserInteractionEnabled = false
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var title: String = "" {
        didSet { titleLabel.text = title }
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.7 : 1 }
    }

    init(textColor: UIColor) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 19

        titleLabel.textColor = textColor
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
