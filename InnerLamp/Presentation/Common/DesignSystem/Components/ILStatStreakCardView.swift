//
//  ILStatStreakCardView.swift
//  InnerLamp
//

import UIKit

/// Thẻ thống kê chuỗi ngày liên tục + biểu đồ cột tuần (mỗi cột 1 ngày, độ đậm = mức độ hoàn thành).
public final class ILStatStreakCardView: UIView {

    // MARK: - Properties
    public var title: String = "" {
        didSet { titleLabel.text = title }
    }

    public var valueText: String = "" {
        didSet { valueLabel.text = valueText }
    }

    public var unitText: String = "" {
        didSet { unitLabel.text = unitText }
    }

    /// 7 giá trị 0...1 — độ đậm mỗi cột (Chủ nhật → Thứ Bảy hoặc theo thứ tự truyền vào).
    public var weekProgress: [Double] = [] {
        didSet { rebuildWeekBars() }
    }

    // MARK: - UI Elements
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let unitLabel = UILabel()
    private let weekStack = UIStackView()

    // MARK: - Initializer
    public init(title: String = "", valueText: String = "", unitText: String = "", weekProgress: [Double] = []) {
        self.title = title
        self.valueText = valueText
        self.unitText = unitText
        self.weekProgress = weekProgress
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
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)

        unitLabel.font = ILTypography.bodySmall
        unitLabel.textColor = ILColors.inkTertiary
        unitLabel.text = unitText

        let valueRow = UIStackView(arrangedSubviews: [valueLabel, unitLabel])
        valueRow.axis = .horizontal
        valueRow.spacing = 6
        valueRow.alignment = .lastBaseline
        valueRow.translatesAutoresizingMaskIntoConstraints = false

        weekStack.axis = .horizontal
        weekStack.spacing = 4
        weekStack.distribution = .fillEqually
        weekStack.translatesAutoresizingMaskIntoConstraints = false

        [titleLabel, valueRow, weekStack].forEach { addSubview($0) }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            valueRow.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            valueRow.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            valueRow.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),

            weekStack.topAnchor.constraint(equalTo: valueRow.bottomAnchor, constant: 12),
            weekStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            weekStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            weekStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18),
            weekStack.heightAnchor.constraint(equalToConstant: 6)
        ])

        rebuildWeekBars()
    }

    private func rebuildWeekBars() {
        weekStack.arrangedSubviews.forEach {
            weekStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for value in weekProgress {
            let bar = UIView()
            bar.layer.cornerRadius = 3
            bar.backgroundColor = ILColors.goldDeep.withAlphaComponent(CGFloat(min(1, max(0, value))))
            weekStack.addArrangedSubview(bar)
        }
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        layer.borderColor = ILColors.border.cgColor
    }
}
