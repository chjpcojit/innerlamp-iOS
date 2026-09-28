//
//  ILStatTileView.swift
//  InnerLamp
//

import UIKit

/// Compact stat tile meant to sit two-up in a row: small title, a medium number with an optional
/// unit beside it, and a one-line footnote whose color the caller picks
/// (e.g. "Tổng thời gian · 168 giờ · +8 giờ so với tháng trước").
public final class ILStatTileView: UIView {

    // MARK: - Constants
    private enum Layout {
        static let padding: CGFloat = 16
        static let valueTopSpacing: CGFloat = 8
        static let valueUnitSpacing: CGFloat = 5
        static let footnoteTopSpacing: CGFloat = 6
    }

    // MARK: - Properties
    public var title: String = "" {
        didSet { titleLabel.text = title }
    }

    public var valueText: String = "" {
        didSet { valueLabel.text = valueText }
    }

    /// Hidden when empty.
    public var unitText: String = "" {
        didSet {
            unitLabel.text = unitText
            unitLabel.isHidden = unitText.isEmpty
        }
    }

    public var footnote: String = "" {
        didSet { footnoteLabel.text = footnote }
    }

    public var footnoteColor: UIColor = ILColors.inkSubtle {
        didSet { footnoteLabel.textColor = footnoteColor }
    }

    // MARK: - UI Elements
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let unitLabel = UILabel()
    private let footnoteLabel = UILabel()

    // MARK: - Initializer
    public init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardRegular
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor

        titleLabel.font = ILTypography.subhead
        titleLabel.textColor = ILColors.inkTertiary

        valueLabel.font = ILTypography.statTileValue
        valueLabel.textColor = ILColors.ink
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)

        unitLabel.font = ILTypography.note
        unitLabel.textColor = ILColors.inkTertiary
        unitLabel.isHidden = true

        footnoteLabel.font = ILTypography.label
        footnoteLabel.textColor = footnoteColor
        footnoteLabel.numberOfLines = 0

        let valueRow = UIStackView(arrangedSubviews: [valueLabel, unitLabel, UIView()])
        valueRow.axis = .horizontal
        valueRow.alignment = .lastBaseline
        valueRow.spacing = Layout.valueUnitSpacing

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueRow, footnoteLabel])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.setCustomSpacing(Layout.valueTopSpacing, after: titleLabel)
        stack.setCustomSpacing(Layout.footnoteTopSpacing, after: valueRow)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: Layout.padding),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.padding),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.padding),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -Layout.padding)
        ])
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILStatTileView, _) in
            view.applyColorAppearanceChange()
        }
    }

    private func applyColorAppearanceChange() {
        layer.borderColor = ILColors.border.cgColor
    }
}
