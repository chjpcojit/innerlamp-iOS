//
//  ILMemorialPreviewCardView.swift
//  InnerLamp
//

import UIKit

/// Live preview under the date pickers (design handoff `prev1` / `prev2`): the next giỗ date on
/// the first line, its lunar/solar equivalent and ordinal on the second. Hidden when both are empty.
final class ILMemorialPreviewCardView: UIView {

    // MARK: - UI Elements
    private lazy var nextLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.bodySmall
        label.textColor = ILColors.ink
        label.numberOfLines = 0
        return label
    }()

    private lazy var detailLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.bodySmall
        label.textColor = ILColors.inkSecondary
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public API
    func configure(next: String, detail: String) {
        nextLabel.text = next
        detailLabel.text = detail
        detailLabel.isHidden = detail.isEmpty
        isHidden = next.isEmpty && detail.isEmpty
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.goldCallout
        layer.cornerRadius = ILMetrics.radiusInput

        let stack = UIStackView(arrangedSubviews: [nextLabel, detailLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: ILMetrics.spaceMedium - 2),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -(ILMetrics.spaceMedium - 2)),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.spaceMedium),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.spaceMedium)
        ])
    }
}
