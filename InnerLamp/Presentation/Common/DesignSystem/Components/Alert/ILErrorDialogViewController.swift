//
//  ILErrorDialogViewController.swift
//  InnerLamp
//

import UIKit

/// Center error dialog ("Dialog giữa màn hình") for errors that block the flow: centered card,
/// "!" badge that shakes once on entrance, Lora title, message, then an outlined secondary pill
/// and a solid primary pill side by side. The user must pick a button — tapping the scrim does
/// nothing (design rule: "buộc chọn một trong hai").
final class ILErrorDialogViewController: ILAlertModalViewController {

    // MARK: - Properties
    private let titleText: String
    private let messageText: String
    private let primaryAction: ILAlertAction
    private let secondaryAction: ILAlertAction?

    override var appearDuration: TimeInterval { 0.28 }

    // MARK: - UI Elements
    private let dimmingView = UIView()
    private let cardView = UIView()
    private let glyphView = ILAlertGlyphView(
        diameter: ILMetrics.Alert.glyphDialog,
        font: ILTypography.alertTitle,
        fillColor: ILColors.Alert.glyphTint,
        glyphColor: ILColors.roseText
    )
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let buttonStack = UIStackView()
    private let contentStack = UIStackView()

    // MARK: - Initializer
    init(title: String, message: String, primary: ILAlertAction, secondary: ILAlertAction?) {
        self.titleText = title
        self.messageText = message
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

        dimmingView.backgroundColor = ILColors.scrimDialog
        view.addSubview(dimmingView)

        cardView.backgroundColor = ILColors.surface
        cardView.layer.cornerRadius = ILMetrics.radiusCardLarge
        cardView.layer.cornerCurve = .continuous
        applyShadow()
        view.addSubview(cardView)

        titleLabel.font = ILTypography.scriptureTitle
        titleLabel.textColor = ILColors.ink
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.text = titleText
        titleLabel.accessibilityTraits = .header

        messageLabel.numberOfLines = 0
        messageLabel.attributedText = ILTypography.makeParagraph(
            text: messageText, font: ILTypography.bodyCompact, color: ILColors.inkDim, cssLineHeight: 1.65, alignment: .center
        )

        // Design order: secondary (outlined) on the left, primary (solid) on the right.
        buttonStack.axis = .horizontal
        buttonStack.spacing = ILMetrics.rowSpacing
        buttonStack.distribution = .fillEqually
        if let secondaryAction {
            let secondaryButton = ILAlertPillButton(title: secondaryAction.title, style: .dialogSecondary)
            secondaryButton.onTap = closeThenRun(secondaryAction)
            buttonStack.addArrangedSubview(secondaryButton)
        }
        let primaryButton = ILAlertPillButton(title: primaryAction.title, style: .dialogPrimary)
        primaryButton.onTap = closeThenRun(primaryAction)
        buttonStack.addArrangedSubview(primaryButton)

        contentStack.axis = .vertical
        contentStack.alignment = .center
        [glyphView, titleLabel, messageLabel, buttonStack].forEach(contentStack.addArrangedSubview)
        contentStack.setCustomSpacing(ILMetrics.spaceStandard, after: glyphView)
        contentStack.setCustomSpacing(9, after: titleLabel)
        contentStack.setCustomSpacing(22, after: messageLabel)
        cardView.addSubview(contentStack)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILErrorDialogViewController, _) in
            view.applyColorAppearanceChange()
        }
    }

    override func setupConstraints() {
        super.setupConstraints()
        [dimmingView, cardView, contentStack].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let margin = ILMetrics.Alert.dialogMargin
        let preferredWidth = cardView.widthAnchor.constraint(equalToConstant: ILMetrics.Alert.dialogMaxWidth)
        preferredWidth.priority = .defaultHigh

        NSLayoutConstraint.activate([
            dimmingView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            cardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: margin),
            cardView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: margin),
            preferredWidth,

            contentStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 26),
            contentStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -22),
            contentStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 22),
            contentStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -22),

            titleLabel.widthAnchor.constraint(equalTo: contentStack.widthAnchor),
            messageLabel.widthAnchor.constraint(equalTo: contentStack.widthAnchor),
            buttonStack.widthAnchor.constraint(equalTo: contentStack.widthAnchor)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cardView.layer.shadowPath = UIBezierPath(roundedRect: cardView.bounds, cornerRadius: ILMetrics.radiusCardLarge).cgPath
    }

    private func applyColorAppearanceChange() {
        applyShadow()
    }

    private func applyShadow() {
        traitCollection.performAsCurrent { ILMetrics.shadowAlertDialog.apply(to: cardView.layer) }
    }

    // MARK: - Animation (design: scrim `ilfade .26s`, card `ilpop .28s`, glyph `ilshake .5s .28s`)
    override func applyHiddenState() {
        dimmingView.alpha = 0
        cardView.alpha = 0
        cardView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
    }

    override func applyShownState() {
        dimmingView.alpha = 1
        cardView.alpha = 1
        cardView.transform = .identity
    }

    override func didAnimateIn() {
        glyphView.shake(delay: appearDuration)
    }
}
