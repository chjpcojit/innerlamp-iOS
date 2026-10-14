//
//  ILConfirmDialogViewController.swift
//  InnerLamp
//

import UIKit

/// Compact confirmation ("Đăng xuất?"): centered card, title + message, then a hairline and two
/// equal cells — cancel (link colour) on the left, destructive confirm (`danger`, semibold) on the
/// right. Tapping the scrim cancels, like the design's `loClose`.
final class ILConfirmDialogViewController: ILAlertModalViewController {

    // MARK: - Properties
    private let titleText: String
    private let messageText: String
    private let cancelAction: ILAlertAction
    private let confirmAction: ILAlertAction

    override var appearDuration: TimeInterval { 0.22 }

    // MARK: - UI Elements
    private let dimmingView = UIView()
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let topHairline = UIView()
    private let verticalHairline = UIView()
    private let cancelCell: ConfirmCell
    private let confirmCell: ConfirmCell

    // MARK: - Initializer
    init(title: String, message: String, cancel: ILAlertAction, confirm: ILAlertAction) {
        self.titleText = title
        self.messageText = message
        self.cancelAction = cancel
        self.confirmAction = confirm
        self.cancelCell = ConfirmCell(title: cancel.title, font: ILTypography.confirmDialogButton, color: ILColors.link)
        self.confirmCell = ConfirmCell(title: confirm.title, font: ILTypography.title2, color: ILColors.danger)
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()

        dimmingView.backgroundColor = ILColors.Alert.scrimConfirm
        dimmingView.isAccessibilityElement = false
        let scrimTap = UITapGestureRecognizer(target: self, action: #selector(handleCancel))
        dimmingView.addGestureRecognizer(scrimTap)
        view.addSubview(dimmingView)

        cardView.backgroundColor = ILColors.surface
        cardView.layer.cornerRadius = ILMetrics.Alert.confirmRadius
        cardView.layer.cornerCurve = .continuous
        applyShadow()
        view.addSubview(cardView)

        titleLabel.font = ILTypography.title2
        titleLabel.textColor = ILColors.ink
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.text = titleText
        titleLabel.accessibilityTraits = .header

        messageLabel.font = ILTypography.bodyCompact
        messageLabel.textColor = ILColors.inkDim
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.text = messageText

        [topHairline, verticalHairline].forEach { $0.backgroundColor = ILColors.Alert.hairline }

        cancelCell.onTap = { [weak self] in self?.handleCancel() }
        confirmCell.onTap = { [weak self] in self?.handleConfirm() }

        [titleLabel, messageLabel, topHairline, cancelCell, confirmCell, verticalHairline].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            cardView.addSubview($0)
        }
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILConfirmDialogViewController, _) in
            view.applyShadow()
        }
    }

    override func setupConstraints() {
        super.setupConstraints()
        [dimmingView, cardView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let margin = ILMetrics.Alert.confirmMargin
        let preferredWidth = cardView.widthAnchor.constraint(equalToConstant: ILMetrics.Alert.confirmMaxWidth)
        preferredWidth.priority = .defaultHigh
        let hairline: CGFloat = 1 / view.traitCollection.displayScale

        NSLayoutConstraint.activate([
            dimmingView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            cardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: margin),
            preferredWidth,

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -18),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            messageLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            topHairline.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 18),
            topHairline.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            topHairline.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            topHairline.heightAnchor.constraint(equalToConstant: hairline),

            cancelCell.topAnchor.constraint(equalTo: topHairline.bottomAnchor),
            cancelCell.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            cancelCell.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            cancelCell.heightAnchor.constraint(equalToConstant: ILMetrics.Alert.confirmButtonHeight),

            confirmCell.topAnchor.constraint(equalTo: cancelCell.topAnchor),
            confirmCell.bottomAnchor.constraint(equalTo: cancelCell.bottomAnchor),
            confirmCell.leadingAnchor.constraint(equalTo: cancelCell.trailingAnchor),
            confirmCell.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            confirmCell.widthAnchor.constraint(equalTo: cancelCell.widthAnchor),

            verticalHairline.topAnchor.constraint(equalTo: cancelCell.topAnchor),
            verticalHairline.bottomAnchor.constraint(equalTo: cancelCell.bottomAnchor),
            verticalHairline.leadingAnchor.constraint(equalTo: confirmCell.leadingAnchor),
            verticalHairline.widthAnchor.constraint(equalToConstant: hairline)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cardView.layer.shadowPath = UIBezierPath(
            roundedRect: cardView.bounds,
            cornerRadius: ILMetrics.Alert.confirmRadius
        ).cgPath
    }

    private func applyShadow() {
        traitCollection.performAsCurrent { ILMetrics.shadowAlertConfirm.apply(to: cardView.layer) }
    }

    // MARK: - Actions
    @objc private func handleCancel() {
        close(completion: cancelAction.handler)
    }

    private func handleConfirm() {
        close(completion: confirmAction.handler)
    }

    // MARK: - Animation
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
}

// MARK: - ConfirmCell
/// One tappable half of the confirm dialog's button row; tints on press like the design's
/// `style-active`.
private final class ConfirmCell: UIControl {

    var onTap: (() -> Void)?

    override var isHighlighted: Bool {
        didSet { backgroundColor = isHighlighted ? ILColors.Alert.confirmCellPressed : .clear }
    }

    init(title: String, font: UIFont, color: UIColor) {
        super.init(frame: .zero)
        let label = UILabel()
        label.text = title
        label.font = font
        label.textColor = color
        label.textAlignment = .center
        label.isUserInteractionEnabled = false
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: ILMetrics.spaceSmall),
            label.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -ILMetrics.spaceSmall)
        ])
        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityTraits = .button
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func handleTap() {
        onTap?()
    }
}
