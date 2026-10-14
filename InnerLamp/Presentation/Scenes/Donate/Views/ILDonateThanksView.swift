//
//  ILDonateThanksView.swift
//  InnerLamp
//

import UIKit

/// Thank-you state: lotus, "Cảm ơn bạn", body mentioning the amount, and a "Quay lại" button.
final class ILDonateThanksView: UIView {

    private enum Layout {
        static let iconSize: CGFloat = 64
        static let bodyMaxWidth: CGFloat = 290
        static let buttonMinWidth: CGFloat = 160
    }

    var onBack: (() -> Void)?

    var bodyText: String = "" {
        didSet { bodyLabel.text = bodyText }
    }

    private lazy var iconView: UIImageView = {
        let imageView = UIImageView(image: ILIcons.rowLotus)
        imageView.tintColor = ILColors.medGold
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.displayLarge
        label.textColor = ILColors.medInk
        label.textAlignment = .center
        label.text = "donate.thanks.title".localized
        return label
    }()

    private lazy var bodyLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.scriptureDescription
        label.textColor = ILColors.medInkStrong
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var backButton: ILButton = {
        let button = ILButton(title: "common.back".localized, variant: .ghost)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backButton.onTap = { [weak self] in self?.onBack?() }

        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel, bodyLabel, backButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = ILMetrics.spaceMedium
        stack.setCustomSpacing(ILMetrics.groupSpacing, after: iconView)
        stack.setCustomSpacing(ILMetrics.spaceLarge, after: bodyLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: Layout.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Layout.iconSize),
            bodyLabel.widthAnchor.constraint(lessThanOrEqualToConstant: Layout.bodyMaxWidth),
            backButton.widthAnchor.constraint(greaterThanOrEqualToConstant: Layout.buttonMinWidth),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: ILMetrics.spaceLarge),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -ILMetrics.spaceLarge)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
