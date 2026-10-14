//
//  ILDonateInfoTableView.swift
//  InnerLamp
//

import UIKit

/// Bordered card listing the transfer details as title / value rows with hairline separators.
final class ILDonateInfoTableView: UIView {

    private var rows: [ILDonateStateModel.InfoRow] = []
    private lazy var stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = ILColors.medTrackSubtle
        layer.cornerRadius = ILMetrics.radiusCardSmall
        layer.borderWidth = 1
        layer.borderColor = ILColors.medTrack.cgColor
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.spaceStandard),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.spaceStandard),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(rows newRows: [ILDonateStateModel.InfoRow]) {
        guard newRows != rows else { return }
        rows = newRows
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, row) in newRows.enumerated() {
            stack.addArrangedSubview(makeRow(row, showsSeparator: index > 0))
        }
    }

    private func makeRow(_ row: ILDonateStateModel.InfoRow, showsSeparator: Bool) -> UIView {
        let titleLabel = UILabel()
        titleLabel.font = ILTypography.bodySmall
        titleLabel.textColor = ILColors.medInkTertiary
        titleLabel.text = row.title
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)

        let valueLabel = UILabel()
        valueLabel.font = ILTypography.bodySmallMedium
        valueLabel.textColor = ILColors.medInk
        valueLabel.textAlignment = .right
        valueLabel.numberOfLines = 0
        valueLabel.text = row.value

        let content = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        content.axis = .horizontal
        content.alignment = .firstBaseline
        content.spacing = ILMetrics.spaceMedium
        content.isLayoutMarginsRelativeArrangement = true
        content.layoutMargins = UIEdgeInsets(top: 11, left: 0, bottom: 11, right: 0)

        let container = UIStackView(arrangedSubviews: [content])
        container.axis = .vertical
        if showsSeparator {
            let separator = UIView()
            separator.backgroundColor = ILColors.medTrack
            separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
            container.insertArrangedSubview(separator, at: 0)
        }
        return container
    }
}
