//
//  ILMalaCompletionView.swift
//  InnerLamp
//

import UIKit

/// Lớp phủ "Tròn N biến" hiện khi đủ mục tiêu của một vòng: thẻ tối giữa màn với giọt sáng, tiêu đề
/// serif, lời hồi hướng và hai nút ("Niệm tiếp vòng mới" / "Xong"). Phủ kín màn mala để chặn chạm
/// xuống dây hạt. Feature-scoped — chỉ Mala dùng.
final class ILMalaCompletionView: UIView {

    // MARK: - Properties
    var title: String = "" {
        didSet { titleLabel.text = title }
    }

    var message: String = "" {
        didSet { messageLabel.text = message }
    }

    var continueTitle: String = "" {
        didSet { continueButton.title = continueTitle }
    }

    var doneTitle: String = "" {
        didSet { doneButton.title = doneTitle }
    }

    var onContinue: (() -> Void)?
    var onDone: (() -> Void)?

    // MARK: - UI Elements
    private let cardView = UIView()
    private let cardGradient = CAGradientLayer()
    private let glowView = UIView()
    private let dropLayer = CAGradientLayer()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let continueButton = ILButton(title: "", variant: .gold)
    private let doneButton = ILButton(title: "", variant: .onDark)

    private let glowSize: CGFloat = 56
    private let dropSize = CGSize(width: 14, height: 19)

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.scrimDialog
        accessibilityViewIsModal = true

        cardView.layer.cornerRadius = ILMetrics.radiusCardLarge + 2
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = ILColors.goldBorderOnDark.cgColor
        cardView.clipsToBounds = true
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardGradient.colors = [ILColors.darkBackgroundTop.cgColor, ILColors.darkBackground.cgColor]
        cardView.layer.insertSublayer(cardGradient, at: 0)
        addSubview(cardView)

        glowView.backgroundColor = ILColors.goldGlowStrong
        glowView.layer.cornerRadius = glowSize / 2
        dropLayer.colors = [ILColors.goldBright.cgColor, ILColors.gold.cgColor]
        dropLayer.cornerRadius = dropSize.width / 2
        glowView.layer.addSublayer(dropLayer)

        titleLabel.font = ILTypography.scriptureTitle
        titleLabel.textColor = ILColors.inkOnDark
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        messageLabel.font = ILTypography.bodyCompact
        messageLabel.textColor = ILColors.inkOnDarkSecondary
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        continueButton.onTap = { [weak self] in self?.onContinue?() }
        doneButton.onTap = { [weak self] in self?.onDone?() }

        let buttonRow = UIStackView(arrangedSubviews: [continueButton, doneButton])
        buttonRow.axis = .horizontal
        buttonRow.distribution = .fillEqually
        buttonRow.spacing = ILMetrics.rowSpacing

        // A fixed-size view inside a `.fill` vertical stack would be stretched — center it in a row.
        let glowRow = UIView()
        glowView.translatesAutoresizingMaskIntoConstraints = false
        glowRow.addSubview(glowView)

        let content = UIStackView(arrangedSubviews: [glowRow, titleLabel, messageLabel, buttonRow])
        content.axis = .vertical
        content.alignment = .fill
        content.spacing = ILMetrics.spaceSmall
        content.setCustomSpacing(ILMetrics.spaceStandard, after: glowRow)
        content.setCustomSpacing(ILMetrics.groupSpacing, after: messageLabel)
        content.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(content)

        NSLayoutConstraint.activate([
            cardView.centerYAnchor.constraint(equalTo: centerYAnchor),
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.spaceLarge),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.spaceLarge),

            content.topAnchor.constraint(equalTo: cardView.topAnchor, constant: ILMetrics.spaceLarge),
            content.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -ILMetrics.spaceLarge),
            content.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: ILMetrics.groupSpacing),
            content.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -ILMetrics.groupSpacing),

            glowView.widthAnchor.constraint(equalToConstant: glowSize),
            glowView.heightAnchor.constraint(equalToConstant: glowSize),
            glowView.topAnchor.constraint(equalTo: glowRow.topAnchor),
            glowView.bottomAnchor.constraint(equalTo: glowRow.bottomAnchor),
            glowView.centerXAnchor.constraint(equalTo: glowRow.centerXAnchor)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        cardGradient.frame = cardView.bounds
        dropLayer.frame = CGRect(
            x: (glowSize - dropSize.width) / 2,
            y: (glowSize - dropSize.height) / 2,
            width: dropSize.width,
            height: dropSize.height
        )
    }
}
