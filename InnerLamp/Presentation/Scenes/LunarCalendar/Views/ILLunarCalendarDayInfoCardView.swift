//
//  ILLunarCalendarDayInfoCardView.swift
//  InnerLamp
//

import UIKit

/// Thẻ tối dưới lịch: eyebrow "HÔM NAY · 16 THÁNG BẢY", tiêu đề Lora và mô tả ngắn cho ngày đang
/// chọn. Gradient tối cố định (không đảo theo theme) theo design handoff.
final class ILLunarCalendarDayInfoCardView: UIView {

    // MARK: - Properties
    var eyebrowText: String = "" {
        didSet {
            eyebrowLabel.attributedText = ILTypography.makeEyebrow(
                text: eyebrowText,
                color: ILColors.goldBright.withAlphaComponent(0.9)
            )
        }
    }

    var titleText: String = "" {
        didSet {
            titleLabel.attributedText = ILTypography.makeAttributedString(
                text: titleText,
                font: ILTypography.scriptureBodyLarge,
                color: ILColors.inkOnDark,
                lineHeightMultiple: 1.4
            )
        }
    }

    var bodyText: String = "" {
        didSet {
            bodyLabel.attributedText = ILTypography.makeAttributedString(
                text: bodyText,
                font: ILTypography.bodySmall,
                color: ILColors.inkOnDarkTagline,
                lineHeightMultiple: 1.6
            )
        }
    }

    // MARK: - UI Elements
    private let gradientLayer = CAGradientLayer()

    private let eyebrowLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private let bodyLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    // MARK: - Setup
    private func setupViews() {
        layer.cornerRadius = ILMetrics.radiusCardSmall + 2
        clipsToBounds = true

        gradientLayer.colors = [ILColors.darkBackgroundTop.cgColor, ILColors.darkBackground.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.2, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.8, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)

        let stack = UIStackView(arrangedSubviews: [eyebrowLabel, titleLabel, bodyLabel])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = ILMetrics.spaceSmall
        stack.setCustomSpacing(10, after: eyebrowLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        let padding = ILMetrics.groupSpacing
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding)
        ])
    }
}
