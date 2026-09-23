//
//  ILSnackbarView.swift
//  InnerLamp
//

import UIKit

/// Bottom snackbar ("Snackbar dưới"): one dark line with a rose status dot and at most one
/// uppercase gold action. Auto-dismisses like the toast; swipe down to dismiss early.
public final class ILSnackbarView: ILAlertOverlayView {

    // MARK: - UI Elements
    private let dotView = UIView()
    private let messageLabel = UILabel()
    private let actionButton: UIButton?

    // MARK: - Initializer
    init(message: String, action: ILAlertAction?) {
        actionButton = action.map { _ in UIButton(type: .system) }
        super.init(
            edge: .bottom,
            cornerRadius: ILMetrics.Alert.snackbarRadius,
            background: ILColors.nightInk,
            borderColor: nil,
            shadow: ILMetrics.shadowSnackbar
        )
        messageLabel.attributedText = ILTypography.makeParagraph(
            text: message, font: ILTypography.bodySmall, color: ILColors.inkOnDarkVariant, cssLineHeight: 1.45
        )
        if let action, let actionButton {
            actionButton.setAttributedTitle(
                ILTypography.makeAttributedString(
                    text: action.title.uppercased(),
                    font: ILTypography.bodySmallMedium,
                    color: ILColors.goldEmber,
                    letterSpacingEm: 0.02
                ),
                for: .normal
            )
            actionButton.accessibilityLabel = action.title
            let run = dismissThenRun(action)
            actionButton.addAction(UIAction { _ in run() }, for: .touchUpInside)
        }
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        dotView.backgroundColor = ILColors.rose
        dotView.layer.cornerRadius = ILMetrics.Alert.snackbarDot / 2
        dotView.translatesAutoresizingMaskIntoConstraints = false

        messageLabel.numberOfLines = 0
        messageLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        actionButton?.setContentHuggingPriority(.required, for: .horizontal)
        actionButton?.setContentCompressionResistancePriority(.required, for: .horizontal)

        let rowStack = UIStackView(arrangedSubviews: [dotView, messageLabel] + [actionButton].compactMap { $0 })
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.spacing = 12
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(rowStack)

        NSLayoutConstraint.activate([
            dotView.widthAnchor.constraint(equalToConstant: ILMetrics.Alert.snackbarDot),
            dotView.heightAnchor.constraint(equalToConstant: ILMetrics.Alert.snackbarDot),

            rowStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 13),
            rowStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -13),
            rowStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ILMetrics.spaceMedium),
            rowStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ILMetrics.spaceMedium)
        ])
    }
}
