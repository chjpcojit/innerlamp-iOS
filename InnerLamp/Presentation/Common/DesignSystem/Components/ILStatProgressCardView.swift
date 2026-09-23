//
//  ILStatProgressCardView.swift
//  InnerLamp
//

import UIKit

/// Thẻ thống kê dạng "giá trị / mục tiêu" + thanh tiến trình — vd "Thời khóa hôm nay: 12 / 20 phút".
public final class ILStatProgressCardView: UIView {

    // MARK: - Properties
    public var title: String = "" {
        didSet { titleLabel.text = title }
    }

    public var valueText: String = "" {
        didSet { valueLabel.text = valueText }
    }

    /// 0...1
    public var progress: Double = 0 {
        didSet { progressBar.progress = progress }
    }

    // MARK: - UI Elements
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let progressBar = ILLinearProgressBarView()

    // MARK: - Initializer
    public init(title: String = "", valueText: String = "", progress: Double = 0) {
        self.title = title
        self.valueText = valueText
        self.progress = progress
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardSmall
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor

        titleLabel.font = ILTypography.bodySmall
        titleLabel.textColor = ILColors.inkTertiary
        titleLabel.text = title
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        valueLabel.font = ILTypography.title2
        valueLabel.textColor = ILColors.ink
        valueLabel.text = valueText
        valueLabel.numberOfLines = 1
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        progressBar.progress = progress
        progressBar.translatesAutoresizingMaskIntoConstraints = false

        [titleLabel, valueLabel, progressBar].forEach { addSubview($0) }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            progressBar.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 12),
            progressBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            progressBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            progressBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18)
        ])
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        layer.borderColor = ILColors.border.cgColor
    }
}
