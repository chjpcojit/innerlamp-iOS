//
//  ILStatBreakdownCardView.swift
//  InnerLamp
//

import UIKit

/// Card showing how a whole splits into parts: a title, one segmented horizontal bar (one colored
/// segment per item) and a legend row per item — dot, name, value
/// (e.g. "Phân bổ pháp hành · Thiền hơi thở 42%" on Stats).
public final class ILStatBreakdownCardView: UIView {

    /// One part of the breakdown.
    public struct Item {
        public let name: String
        /// 0...1 share of the bar.
        public let fraction: Double
        public let valueText: String
        public let color: UIColor

        public init(name: String, fraction: Double, valueText: String, color: UIColor) {
            self.name = name
            self.fraction = fraction
            self.valueText = valueText
            self.color = color
        }
    }

    // MARK: - Constants
    private enum Layout {
        static let padding: CGFloat = 18
        static let barHeight: CGFloat = 10
        static let barTopSpacing: CGFloat = 14
        static let legendTopSpacing: CGFloat = 16
        static let legendRowSpacing: CGFloat = 10
        static let dotSize: CGFloat = 9
    }

    // MARK: - Properties
    public var title: String = "" {
        didSet { titleLabel.text = title }
    }

    public var items: [Item] = [] {
        didSet { rebuild() }
    }

    // MARK: - UI Elements
    private let titleLabel = UILabel()
    private let barView = UIView()
    private let legendStack = UIStackView()
    private var segmentViews: [UIView] = []

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

        titleLabel.font = ILTypography.sectionTitle
        titleLabel.textColor = ILColors.ink
        titleLabel.accessibilityTraits = .header

        barView.layer.cornerRadius = Layout.barHeight / 2
        barView.clipsToBounds = true
        barView.isAccessibilityElement = false
        barView.heightAnchor.constraint(equalToConstant: Layout.barHeight).isActive = true

        legendStack.axis = .vertical
        legendStack.alignment = .fill
        legendStack.spacing = Layout.legendRowSpacing

        let stack = UIStackView(arrangedSubviews: [titleLabel, barView, legendStack])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.setCustomSpacing(Layout.barTopSpacing, after: titleLabel)
        stack.setCustomSpacing(Layout.legendTopSpacing, after: barView)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: Layout.padding),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.padding),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.padding),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.padding)
        ])
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILStatBreakdownCardView, _) in
            view.applyColorAppearanceChange()
        }
    }

    private func rebuild() {
        rebuildBar()
        rebuildLegend()
    }

    /// Segments are chained left → right, each sized as a fraction of the whole bar width.
    private func rebuildBar() {
        segmentViews.forEach { $0.removeFromSuperview() }
        segmentViews = items.map { item in
            let segment = UIView()
            segment.backgroundColor = item.color
            segment.translatesAutoresizingMaskIntoConstraints = false
            barView.addSubview(segment)
            NSLayoutConstraint.activate([
                segment.topAnchor.constraint(equalTo: barView.topAnchor),
                segment.bottomAnchor.constraint(equalTo: barView.bottomAnchor),
                segment.widthAnchor.constraint(
                    equalTo: barView.widthAnchor,
                    multiplier: CGFloat(min(max(item.fraction, 0), 1))
                )
            ])
            return segment
        }
        var previousAnchor = barView.leadingAnchor
        for segment in segmentViews {
            segment.leadingAnchor.constraint(equalTo: previousAnchor).isActive = true
            previousAnchor = segment.trailingAnchor
        }
    }

    private func rebuildLegend() {
        legendStack.arrangedSubviews.forEach {
            legendStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for item in items {
            legendStack.addArrangedSubview(makeLegendRow(item))
        }
    }

    private func makeLegendRow(_ item: Item) -> UIView {
        let dot = UIView()
        dot.backgroundColor = item.color
        dot.layer.cornerRadius = Layout.dotSize / 2
        dot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dot.widthAnchor.constraint(equalToConstant: Layout.dotSize),
            dot.heightAnchor.constraint(equalToConstant: Layout.dotSize)
        ])

        let nameLabel = UILabel()
        nameLabel.font = ILTypography.bodySmall
        nameLabel.textColor = ILColors.inkSecondary
        nameLabel.text = item.name

        let valueLabel = UILabel()
        valueLabel.font = ILTypography.chip
        valueLabel.textColor = ILColors.ink
        valueLabel.text = item.valueText
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [dot, nameLabel, valueLabel])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = Layout.legendRowSpacing
        row.isAccessibilityElement = true
        row.accessibilityLabel = "\(item.name), \(item.valueText)"
        return row
    }

    private func applyColorAppearanceChange() {
        layer.borderColor = ILColors.border.cgColor
    }
}
