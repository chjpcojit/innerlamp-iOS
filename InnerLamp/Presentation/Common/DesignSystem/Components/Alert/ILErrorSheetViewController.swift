//
//  ILErrorSheetViewController.swift
//  InnerLamp
//

import UIKit

/// Error bottom sheet ("Bottom sheet lỗi") for errors with longer context: grabber, large "!"
/// badge, Lora title, message, optional error-code box, then a primary and an optional ghost
/// `ILButton`. Dismissed by a button, tapping the scrim, or dragging the sheet down.
final class ILErrorSheetViewController: ILAlertModalViewController {

    // MARK: - Properties
    private let titleText: String
    private let messageText: String
    private let errorCode: String?
    private let primaryAction: ILAlertAction
    private let secondaryAction: ILAlertAction?

    override var appearDuration: TimeInterval { 0.34 }

    // MARK: - UI Elements
    private let dimmingView = UIView()
    private let sheetView = UIView()
    private let grabberView = UIView()
    private let glyphView = ILAlertGlyphView(
        diameter: ILMetrics.Alert.glyphSheet,
        font: ILTypography.alertTitle,
        fillColor: ILColors.Alert.glyphTint,
        glyphColor: ILColors.roseText
    )
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let codeBox = UIView()
    private let codeCaptionLabel = UILabel()
    private let codeValueLabel = UILabel()
    private let contentStack = UIStackView()

    // MARK: - Initializer
    init(title: String, message: String, errorCode: String?, primary: ILAlertAction, secondary: ILAlertAction?) {
        self.titleText = title
        self.messageText = message
        self.errorCode = errorCode
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

        dimmingView.backgroundColor = ILColors.scrimSheet
        dimmingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDimmingTap)))
        view.addSubview(dimmingView)

        sheetView.backgroundColor = ILColors.surface
        sheetView.layer.cornerRadius = ILMetrics.Alert.sheetRadius
        sheetView.layer.cornerCurve = .continuous
        sheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheetView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
        applyShadow()
        view.addSubview(sheetView)

        grabberView.backgroundColor = ILColors.Alert.hairline
        grabberView.layer.cornerRadius = ILMetrics.Alert.grabberSize.height / 2
        grabberView.isAccessibilityElement = false
        sheetView.addSubview(grabberView)

        titleLabel.font = ILTypography.alertTitle
        titleLabel.textColor = ILColors.ink
        titleLabel.numberOfLines = 0
        titleLabel.text = titleText
        titleLabel.accessibilityTraits = .header

        messageLabel.numberOfLines = 0
        messageLabel.attributedText = ILTypography.makeParagraph(
            text: messageText, font: ILTypography.body, color: ILColors.inkDim, cssLineHeight: 1.65
        )

        setupCodeBox()

        let buttonStack = UIStackView()
        buttonStack.axis = .vertical
        buttonStack.spacing = ILMetrics.rowSpacing
        let primaryButton = ILButton(title: primaryAction.title, variant: .primary)
        primaryButton.onTap = closeThenRun(primaryAction)
        buttonStack.addArrangedSubview(primaryButton)
        if let secondaryAction {
            let secondaryButton = ILButton(title: secondaryAction.title, variant: .ghost)
            secondaryButton.onTap = closeThenRun(secondaryAction)
            buttonStack.addArrangedSubview(secondaryButton)
        }

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        [glyphRow(), titleLabel, messageLabel, codeBox, buttonStack].forEach(contentStack.addArrangedSubview)
        contentStack.setCustomSpacing(ILMetrics.spaceStandard, after: contentStack.arrangedSubviews[0])
        contentStack.setCustomSpacing(10, after: titleLabel)
        contentStack.setCustomSpacing(ILMetrics.spaceStandard, after: messageLabel)
        contentStack.setCustomSpacing(ILMetrics.groupSpacing, after: codeBox)
        // When the code box is hidden, the gap after the message is the design's 20pt button gap.
        if errorCode == nil {
            contentStack.setCustomSpacing(ILMetrics.groupSpacing, after: messageLabel)
        }
        sheetView.addSubview(contentStack)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILErrorSheetViewController, _) in
            view.applyColorAppearanceChange()
        }
    }

    /// Glyph is left-aligned in the design, so it sits in a row instead of stretching.
    private func glyphRow() -> UIView {
        let row = UIView()
        row.addSubview(glyphView)
        NSLayoutConstraint.activate([
            glyphView.topAnchor.constraint(equalTo: row.topAnchor),
            glyphView.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            glyphView.leadingAnchor.constraint(equalTo: row.leadingAnchor)
        ])
        return row
    }

    private func setupCodeBox() {
        codeBox.isHidden = errorCode == nil
        codeBox.backgroundColor = ILColors.canvasWarmEnd1
        codeBox.layer.cornerRadius = ILMetrics.radiusInput
        codeBox.isAccessibilityElement = true
        codeBox.accessibilityLabel = errorCode.map { "\("alert.errorCode.label".localized) \($0)" }

        codeCaptionLabel.font = ILTypography.subhead
        codeCaptionLabel.textColor = ILColors.inkSubtle
        codeCaptionLabel.text = "alert.errorCode.label".localized
        codeValueLabel.font = ILTypography.subheadMedium
        codeValueLabel.textColor = ILColors.inkDim
        codeValueLabel.text = errorCode

        let codeStack = UIStackView(arrangedSubviews: [codeCaptionLabel, codeValueLabel, UIView()])
        codeStack.axis = .horizontal
        codeStack.spacing = ILMetrics.spaceSmall
        codeStack.translatesAutoresizingMaskIntoConstraints = false
        codeBox.addSubview(codeStack)

        NSLayoutConstraint.activate([
            codeStack.topAnchor.constraint(equalTo: codeBox.topAnchor, constant: 11),
            codeStack.bottomAnchor.constraint(equalTo: codeBox.bottomAnchor, constant: -11),
            codeStack.leadingAnchor.constraint(equalTo: codeBox.leadingAnchor, constant: 13),
            codeStack.trailingAnchor.constraint(equalTo: codeBox.trailingAnchor, constant: -13)
        ])
    }

    override func setupConstraints() {
        super.setupConstraints()
        [dimmingView, sheetView, grabberView, contentStack].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let horizontal: CGFloat = 22
        // Content sits on the safe-area bottom when there is a home indicator, but never closer
        // than the design's 26pt to the sheet edge.
        let bottomToSafeArea = contentStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        bottomToSafeArea.priority = .defaultHigh

        NSLayoutConstraint.activate([
            dimmingView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            sheetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sheetView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.groupSpacing),

            grabberView.topAnchor.constraint(equalTo: sheetView.topAnchor, constant: 12),
            grabberView.centerXAnchor.constraint(equalTo: sheetView.centerXAnchor),
            grabberView.widthAnchor.constraint(equalToConstant: ILMetrics.Alert.grabberSize.width),
            grabberView.heightAnchor.constraint(equalToConstant: ILMetrics.Alert.grabberSize.height),

            contentStack.topAnchor.constraint(equalTo: grabberView.bottomAnchor, constant: ILMetrics.groupSpacing),
            contentStack.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: horizontal),
            contentStack.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor, constant: -horizontal),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: sheetView.bottomAnchor, constant: -26),
            bottomToSafeArea
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sheetView.layer.shadowPath = UIBezierPath(
            roundedRect: sheetView.bounds,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: ILMetrics.Alert.sheetRadius, height: ILMetrics.Alert.sheetRadius)
        ).cgPath
    }

    private func applyColorAppearanceChange() {
        applyShadow()
    }

    private func applyShadow() {
        traitCollection.performAsCurrent { ILMetrics.shadowAlertSheet.apply(to: sheetView.layer) }
    }

    // MARK: - Animation (design: scrim `ilfade .26s`, sheet `ilup .34s`)
    override func applyHiddenState() {
        dimmingView.alpha = 0
        sheetView.alpha = 0
        sheetView.transform = CGAffineTransform(translationX: 0, y: sheetView.bounds.height * 1.15)
    }

    override func applyShownState() {
        dimmingView.alpha = 1
        sheetView.alpha = 1
        sheetView.transform = .identity
    }

    // MARK: - Actions
    @objc private func handleDimmingTap() {
        close()
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = max(0, gesture.translation(in: view).y)
        let height = max(sheetView.bounds.height, 1)
        switch gesture.state {
        case .changed:
            sheetView.transform = CGAffineTransform(translationX: 0, y: translation)
            dimmingView.alpha = 1 - min(translation / height, 1)
        case .ended, .cancelled:
            let velocity = gesture.velocity(in: view).y
            if translation > height * 0.3 || velocity > 800 {
                close()
            } else {
                UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
                    self.applyShownState()
                }
            }
        default:
            break
        }
    }
}
