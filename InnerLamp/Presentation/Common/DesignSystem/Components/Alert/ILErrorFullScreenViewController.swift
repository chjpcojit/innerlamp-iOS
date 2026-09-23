//
//  ILErrorFullScreenViewController.swift
//  InnerLamp
//

import UIKit

/// Full-screen error ("Toàn màn hình") for severe failures where the app cannot continue.
/// Always dark (like `splash`/`player`): radial night background, round "×", ringed "!" badge,
/// Lora title, italic subtitle, message, `CODE · HH:mm` footnote, then a light primary pill and
/// an outlined secondary pill pinned to the bottom. Fades in (design `ilfade .3s`).
final class ILErrorFullScreenViewController: ILAlertModalViewController {

    // MARK: - Properties
    private let titleText: String
    private let subtitleText: String?
    private let messageText: String
    private let errorCode: String?
    private let occurredAt: Date
    private let primaryAction: ILAlertAction
    private let secondaryAction: ILAlertAction?

    override var appearDuration: TimeInterval { 0.3 }
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    // MARK: - UI Elements
    private let backgroundView = ILImmersiveBackgroundView(style: .alwaysDarkAlert)
    private let closeButton = UIButton(type: .system)
    private let ringView = UIView()
    private let glyphView = ILAlertGlyphView(
        diameter: ILMetrics.Alert.glyphFull,
        font: ILTypography.scriptureBodyLarge,
        fillColor: ILColors.Alert.glyphTint,
        glyphColor: ILColors.roseOnDark
    )
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let messageLabel = UILabel()
    private let footnoteLabel = UILabel()
    private let centerStack = UIStackView()
    private let buttonStack = UIStackView()

    // MARK: - Initializer
    init(
        title: String,
        subtitle: String?,
        message: String,
        errorCode: String?,
        occurredAt: Date = Date(),
        primary: ILAlertAction,
        secondary: ILAlertAction?
    ) {
        self.titleText = title
        self.subtitleText = subtitle
        self.messageText = message
        self.errorCode = errorCode
        self.occurredAt = occurredAt
        self.primaryAction = primary
        self.secondaryAction = secondary
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.addSubview(backgroundView)

        closeButton.setTitle("×", for: .normal)
        closeButton.titleLabel?.font = ILTypography.alertCloseLarge
        closeButton.setTitleColor(ILColors.Alert.fullCloseGlyph, for: .normal)
        closeButton.layer.cornerRadius = ILMetrics.Alert.closeLarge / 2
        closeButton.layer.borderWidth = 1
        closeButton.layer.borderColor = ILColors.Alert.fullBorder.cgColor
        closeButton.accessibilityLabel = "common.close".localized
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        view.addSubview(closeButton)

        ringView.layer.cornerRadius = ILMetrics.Alert.glyphRingFull / 2
        ringView.layer.borderWidth = 1
        ringView.layer.borderColor = ILColors.Alert.glyphRing.cgColor
        ringView.addSubview(glyphView)

        titleLabel.font = ILTypography.displayLarge
        titleLabel.textColor = ILColors.inkOnDark
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.text = titleText
        titleLabel.accessibilityTraits = .header

        subtitleLabel.font = ILTypography.quoteItalic
        subtitleLabel.textColor = ILColors.Alert.fullSubtitle
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text = subtitleText
        subtitleLabel.isHidden = subtitleText == nil

        messageLabel.numberOfLines = 0
        messageLabel.attributedText = ILTypography.makeParagraph(
            text: messageText, font: ILTypography.alertFullBody, color: ILColors.Alert.fullMessage, cssLineHeight: 1.7, alignment: .center
        )

        footnoteLabel.numberOfLines = 0
        footnoteLabel.isHidden = errorCode == nil
        if let errorCode {
            footnoteLabel.attributedText = ILTypography.makeAttributedString(
                text: "\(errorCode) · \(Self.timeFormatter.string(from: occurredAt))",
                font: ILTypography.label,
                color: ILColors.Alert.fullFootnote,
                letterSpacingEm: 0.04,
                alignment: .center
            )
        }

        centerStack.axis = .vertical
        centerStack.alignment = .center
        [ringView, titleLabel, subtitleLabel, messageLabel, footnoteLabel].forEach(centerStack.addArrangedSubview)
        centerStack.setCustomSpacing(ILMetrics.spaceLarge, after: ringView)
        centerStack.setCustomSpacing(10, after: titleLabel)
        centerStack.setCustomSpacing(18, after: subtitleLabel)
        if subtitleText == nil {
            centerStack.setCustomSpacing(18, after: titleLabel)
        }
        centerStack.setCustomSpacing(ILMetrics.groupSpacing, after: messageLabel)
        view.addSubview(centerStack)

        buttonStack.axis = .vertical
        buttonStack.spacing = 11
        let primaryButton = ILAlertPillButton(title: primaryAction.title, style: .fullPrimary)
        primaryButton.onTap = closeThenRun(primaryAction)
        buttonStack.addArrangedSubview(primaryButton)
        if let secondaryAction {
            let secondaryButton = ILAlertPillButton(title: secondaryAction.title, style: .fullSecondary)
            secondaryButton.onTap = closeThenRun(secondaryAction)
            buttonStack.addArrangedSubview(secondaryButton)
        }
        view.addSubview(buttonStack)
    }

    override func setupConstraints() {
        super.setupConstraints()
        [backgroundView, closeButton, ringView, glyphView, centerStack, buttonStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        let horizontal = ILMetrics.immersiveHorizontal
        let safeArea = view.safeAreaLayoutGuide
        // Room the text column may use; the stack is vertically centered between "×" and buttons.
        let contentGuide = UILayoutGuide()
        view.addLayoutGuide(contentGuide)

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            closeButton.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: ILMetrics.rowSpacing),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontal),
            closeButton.widthAnchor.constraint(equalToConstant: ILMetrics.Alert.closeLarge),
            closeButton.heightAnchor.constraint(equalToConstant: ILMetrics.Alert.closeLarge),

            ringView.widthAnchor.constraint(equalToConstant: ILMetrics.Alert.glyphRingFull),
            ringView.heightAnchor.constraint(equalToConstant: ILMetrics.Alert.glyphRingFull),
            glyphView.centerXAnchor.constraint(equalTo: ringView.centerXAnchor),
            glyphView.centerYAnchor.constraint(equalTo: ringView.centerYAnchor),

            messageLabel.widthAnchor.constraint(lessThanOrEqualToConstant: ILMetrics.Alert.fullMessageMaxWidth),

            contentGuide.topAnchor.constraint(equalTo: closeButton.bottomAnchor),
            contentGuide.bottomAnchor.constraint(equalTo: buttonStack.topAnchor),
            centerStack.centerYAnchor.constraint(equalTo: contentGuide.centerYAnchor),
            centerStack.topAnchor.constraint(greaterThanOrEqualTo: contentGuide.topAnchor),
            centerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontal),
            centerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontal),

            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontal),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontal),
            buttonStack.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -ILMetrics.spaceSmall)
        ])
    }

    // MARK: - Animation (design: `ilfade .3s`)
    override func applyHiddenState() {
        view.alpha = 0
    }

    override func applyShownState() {
        view.alpha = 1
    }

    // MARK: - Actions
    @objc private func handleClose() {
        close()
    }
}
