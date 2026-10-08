//
//  ILInlineBannerView.swift
//  InnerLamp
//

import UIKit

/// In-screen confirmation banner (design handoff green "Đã lưu…" strip): a green check dot and a
/// message on a soft green card. Hidden while `message` is empty; the owner decides how long it
/// stays by clearing the message.
public final class ILInlineBannerView: UIView {

    // MARK: - Properties
    public var message: String = "" {
        didSet {
            messageLabel.text = message
            isHidden = message.isEmpty
            accessibilityLabel = message
        }
    }

    // MARK: - UI Elements
    private let checkCircle = UIView()
    private let checkGlyph = UIImageView(image: ILIcons.checkmark)
    private let messageLabel = UILabel()

    // MARK: - Initializer
    public init() {
        super.init(frame: .zero)
        setupViews()
        isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.greenTint
        layer.cornerRadius = ILMetrics.radiusInput
        isAccessibilityElement = true
        accessibilityTraits = .staticText

        checkCircle.backgroundColor = ILColors.green
        checkCircle.layer.cornerRadius = Self.circleSize / 2
        checkCircle.translatesAutoresizingMaskIntoConstraints = false

        checkGlyph.tintColor = ILColors.surface
        checkGlyph.contentMode = .scaleAspectFit
        checkGlyph.translatesAutoresizingMaskIntoConstraints = false
        checkCircle.addSubview(checkGlyph)

        messageLabel.font = ILTypography.bodySmall
        messageLabel.textColor = ILColors.ink
        messageLabel.numberOfLines = 0

        let row = UIStackView(arrangedSubviews: [checkCircle, messageLabel])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = ILMetrics.rowSpacing
        row.isUserInteractionEnabled = false
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        NSLayoutConstraint.activate([
            checkCircle.widthAnchor.constraint(equalToConstant: Self.circleSize),
            checkCircle.heightAnchor.constraint(equalToConstant: Self.circleSize),
            checkGlyph.centerXAnchor.constraint(equalTo: checkCircle.centerXAnchor),
            checkGlyph.centerYAnchor.constraint(equalTo: checkCircle.centerYAnchor),
            checkGlyph.widthAnchor.constraint(equalToConstant: 10),
            checkGlyph.heightAnchor.constraint(equalToConstant: 10),

            row.topAnchor.constraint(equalTo: topAnchor, constant: ILMetrics.spaceMedium - 2),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -(ILMetrics.spaceMedium - 2)),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.spaceMedium),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.spaceMedium)
        ])
    }

    private static let circleSize: CGFloat = 18
}
