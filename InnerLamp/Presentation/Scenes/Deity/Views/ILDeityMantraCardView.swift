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
        static let buttonInset: CGFloat = 16
    }

    var onChantTap: (() -> Void)?
    var onShareTap: (() -> Void)?

    // MARK: - UI Elements
    private let gradientLayer = CAGradientLayer()
    private let glowLayer = CAGradientLayer()

    private let eyebrowLabel = UILabel()
    private let textLabel = UILabel()
    private let sanskritLabel = UILabel()
    private let noteLabel = UILabel()
    private let chantButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)

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
        chantButton.setTitle(chantTitle, for: .normal)
        shareButton.setTitle(shareTitle, for: .normal)
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = ILMetrics.radiusCardRegular
        layer.borderWidth = 1
        clipsToBounds = true

        // `linear-gradient(140deg, start, end)`.
        gradientLayer.startPoint = CGPoint(x: 0.18, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.82, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)

        // `radial-gradient(ellipse 70% 60% at 85% 20%, glow, transparent)`.
        glowLayer.type = .radial
        glowLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        glowLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(glowLayer, above: gradientLayer)

        eyebrowLabel.font = ILTypography.eyebrowSmall

        textLabel.numberOfLines = 0

        sanskritLabel.font = ILTypography.heroSubtitleItalic
        sanskritLabel.textColor = ILColors.templeHeaderSub
        sanskritLabel.numberOfLines = 0

        noteLabel.numberOfLines = 0

        styleButton(chantButton, textColor: ILColors.inkOnGold)
        chantButton.backgroundColor = ILColors.goldBright
        chantButton.addTarget(self, action: #selector(handleChantTapped), for: .touchUpInside)

        styleButton(shareButton, textColor: ILColors.templeHeaderInk)
        shareButton.layer.borderWidth = 1
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

    private func styleButton(_ button: UIButton, textColor: UIColor) {
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: 0, leading: Layout.buttonInset, bottom: 0, trailing: Layout.buttonInset
        )
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = ILTypography.chip
            return attributes
        }
        configuration.baseForegroundColor = textColor
        button.configuration = configuration
        button.layer.cornerRadius = Layout.buttonHeight / 2
        button.clipsToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
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
