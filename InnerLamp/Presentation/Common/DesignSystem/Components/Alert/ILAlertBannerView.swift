//
//  ILAlertBannerView.swift
//  InnerLamp
//

import UIKit

/// Top action banner for errors that need a decision ("Banner trên · có hành động"): dark rose
/// card, "!" badge, title + optional message, then a light primary pill and an outlined
/// secondary pill aligned under the text. Stays until the user taps a pill or swipes it up.
public final class ILAlertBannerView: ILAlertOverlayView {

    // MARK: - UI Elements
    private let glyphView = ILAlertGlyphView(
        diameter: ILMetrics.Alert.glyphSmall,
        font: ILTypography.alertGlyphSmall,
        fillColor: ILColors.Alert.bannerGlyphTint,
        glyphColor: ILColors.alertBannerGlyph
    )
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let primaryButton: ILAlertPillButton
    private let secondaryButton: ILAlertPillButton?

    // MARK: - Initializer
    init(title: String, message: String?, primary: ILAlertAction, secondary: ILAlertAction?) {
        primaryButton = ILAlertPillButton(title: primary.title, style: .bannerPrimary)
        secondaryButton = secondary.map { ILAlertPillButton(title: $0.title, style: .bannerSecondary) }
        super.init(
            edge: .top,
            cornerRadius: ILMetrics.radiusCardSmall,
            background: ILColors.alertBanner,
            borderColor: nil,
            shadow: ILMetrics.shadowAlertBanner
        )
        titleLabel.text = title
        messageLabel.attributedText = message.map {
            ILTypography.makeParagraph(text: $0, font: ILTypography.note, color: ILColors.Alert.bannerMessage, cssLineHeight: 1.5)
        }
        messageLabel.isHidden = message == nil
        primaryButton.onTap = dismissThenRun(primary)
        if let secondary {
            secondaryButton?.onTap = dismissThenRun(secondary)
        }
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        titleLabel.font = ILTypography.alertHeadline
        titleLabel.textColor = ILColors.alertBannerInk
        titleLabel.numberOfLines = 0
        messageLabel.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [titleLabel, messageLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        let headerStack = UIStackView(arrangedSubviews: [glyphView, textStack])
        headerStack.axis = .horizontal
        headerStack.alignment = .top
        headerStack.spacing = 12

        let buttonStack = UIStackView(arrangedSubviews: [primaryButton] + [secondaryButton].compactMap { $0 })
        buttonStack.axis = .horizontal
        buttonStack.spacing = ILMetrics.spaceSmall
        buttonStack.alignment = .center

        // Pills line up with the text column: badge width + badge-to-text gap.
        let buttonRow = UIView()
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonRow.addSubview(buttonStack)

        let mainStack = UIStackView(arrangedSubviews: [headerStack, buttonRow])
        mainStack.axis = .vertical
        mainStack.spacing = 12
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainStack)

        NSLayoutConstraint.activate([
            buttonStack.topAnchor.constraint(equalTo: buttonRow.topAnchor),
            buttonStack.bottomAnchor.constraint(equalTo: buttonRow.bottomAnchor),
            buttonStack.leadingAnchor.constraint(equalTo: buttonRow.leadingAnchor, constant: ILMetrics.Alert.glyphSmall + 12),
            buttonStack.trailingAnchor.constraint(lessThanOrEqualTo: buttonRow.trailingAnchor),

            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: ILMetrics.spaceMedium),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -ILMetrics.spaceMedium),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15)
        ])
    }
}
