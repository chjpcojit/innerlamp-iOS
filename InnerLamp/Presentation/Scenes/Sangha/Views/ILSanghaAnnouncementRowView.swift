//
//  ILSanghaAnnouncementRowView.swift
//  InnerLamp
//

import UIKit

/// 1 thông báo của chùa: mốc thời gian nhỏ phía trên, nội dung phía dưới. Vỏ thẻ do
/// `ILSanghaCardView` đảm nhiệm.
final class ILSanghaAnnouncementRowView: UIView {

    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.caption
        label.textColor = ILColors.inkMuted
        return label
    }()

    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    init() {
        super.init(frame: .zero)

        let stack = UIStackView(arrangedSubviews: [timeLabel, textLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: ILMetrics.spaceMedium),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -ILMetrics.spaceMedium),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.spaceStandard),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.spaceStandard)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(timeText: String, text: String) {
        timeLabel.text = timeText
        textLabel.attributedText = ILTypography.makeAttributedString(
            text: text, font: ILTypography.bodyCompact, color: ILColors.inkSecondary, lineHeightMultiple: 1.6
        )
    }
}
