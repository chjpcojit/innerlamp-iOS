//
//  ILToastView.swift
//  InnerLamp
//

import UIKit

/// Top toast for light errors that need no action ("Toast trên · tự tắt"): light card with a rose
/// border, small "!" badge, title + optional message, "×", and a 2pt rose countdown bar that
/// shrinks while the toast waits to auto-dismiss.
public final class ILToastView: ILAlertOverlayView {

    // MARK: - UI Elements
    private let glyphView = ILAlertGlyphView(
        diameter: ILMetrics.Alert.glyphSmall,
        font: ILTypography.alertGlyphSmall,
        fillColor: ILColors.Alert.glyphTintSmall,
        glyphColor: ILColors.roseText
    )
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    /// Plain layer (not a view) so changing its anchor point does not fight Auto Layout.
    private let countdownLayer = CALayer()

    // MARK: - Initializer
    init(title: String, message: String?) {
        super.init(
            edge: .top,
            cornerRadius: ILMetrics.radiusCardSmall,
            background: ILColors.surface,
            borderColor: ILColors.Alert.toastBorder,
            shadow: ILMetrics.shadowToast
        )
        titleLabel.text = title
        messageLabel.attributedText = message.map {
            ILTypography.makeParagraph(text: $0, font: ILTypography.note, color: ILColors.inkTertiary, cssLineHeight: 1.5)
        }
        messageLabel.isHidden = message == nil
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        titleLabel.font = ILTypography.alertHeadline
        titleLabel.textColor = ILColors.ink
        titleLabel.numberOfLines = 0
        messageLabel.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [titleLabel, messageLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        closeButton.setTitle("×", for: .normal)
        closeButton.titleLabel?.font = ILTypography.alertClose
        closeButton.setTitleColor(ILColors.Alert.closeGlyph, for: .normal)
        closeButton.accessibilityLabel = "common.close".localized
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)

        let rowStack = UIStackView(arrangedSubviews: [glyphView, textStack, closeButton])
        rowStack.axis = .horizontal
        rowStack.alignment = .top
        rowStack.spacing = 12
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(rowStack)

        countdownLayer.backgroundColor = ILColors.rose.cgColor
        countdownLayer.anchorPoint = CGPoint(x: 0, y: 0.5)
        countdownLayer.isHidden = true
        contentView.layer.addSublayer(countdownLayer)

        NSLayoutConstraint.activate([
            rowStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 13),
            rowStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -13),
            rowStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ILMetrics.spaceMedium),
            rowStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ILMetrics.spaceMedium),

            closeButton.widthAnchor.constraint(equalToConstant: ILMetrics.Alert.closeSmall),
            closeButton.heightAnchor.constraint(equalToConstant: ILMetrics.Alert.closeSmall)
        ])
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let height = ILMetrics.Alert.countdownBarHeight
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        // Sized via bounds + position so the running scale animation is untouched.
        countdownLayer.bounds = CGRect(x: 0, y: 0, width: contentView.bounds.width, height: height)
        countdownLayer.position = CGPoint(x: 0, y: contentView.bounds.height - height / 2)
        CATransaction.commit()
    }

    // MARK: - Countdown
    /// Design `ilbar`: `scaleX(1 → 0)` from the left edge, linear, over the auto-dismiss delay.
    override func autoDismissCountdownDidStart(duration: TimeInterval) {
        countdownLayer.isHidden = false
        let shrink = CABasicAnimation(keyPath: "transform.scale.x")
        shrink.fromValue = 1
        shrink.toValue = 0
        shrink.duration = duration
        shrink.timingFunction = CAMediaTimingFunction(name: .linear)
        shrink.fillMode = .forwards
        shrink.isRemovedOnCompletion = false
        countdownLayer.add(shrink, forKey: "countdown")
    }

    // MARK: - Actions
    @objc private func handleClose() {
        dismiss()
    }
}
