//
//  ILStatBarChartCardView.swift
//  InnerLamp
//

import UIKit

/// Card with a title + trailing caption, a row of equal-width vertical bars (height and opacity
/// supplied per bar) and a start/end axis label underneath
/// (e.g. "Thời lượng 12 tuần · TB 22 phút/ngày" on Stats).
public final class ILStatBarChartCardView: UIView {

    /// One bar, both values 0...1.
    public struct Bar: Equatable {
        public let heightRatio: Double
        public let opacity: Double

        public init(heightRatio: Double, opacity: Double) {
            self.heightRatio = heightRatio
            self.opacity = opacity
        }
    }

    // MARK: - Constants
    private enum Layout {
        static let padding: CGFloat = 18
        static let chartHeight: CGFloat = 96
        static let chartTopSpacing: CGFloat = 16
        static let barSpacing: CGFloat = 5
        static let axisTopSpacing: CGFloat = 8
        static let barTopRadius: CGFloat = 5
    }

    // MARK: - Properties
    public var title: String = "" {
        didSet { titleLabel.text = title }
    }

    public var trailingText: String = "" {
        didSet { trailingLabel.text = trailingText }
    }

    public var startLabelText: String = "" {
        didSet { startLabel.text = startLabelText }
    }

    public var endLabelText: String = "" {
        didSet { endLabel.text = endLabelText }
    }

    public var barColor: UIColor = ILColors.gold {
        didSet { rebuildBars() }
    }

    public var bars: [Bar] = [] {
        didSet { rebuildBars() }
    }

    // MARK: - UI Elements
    private let titleLabel = UILabel()
    private let trailingLabel = UILabel()
    private let barsStack = UIStackView()
    private let startLabel = UILabel()
    private let endLabel = UILabel()

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

        trailingLabel.font = ILTypography.subhead
        trailingLabel.textColor = ILColors.inkSubtle
        trailingLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let headerRow = UIStackView(arrangedSubviews: [titleLabel, UIView(), trailingLabel])
        headerRow.axis = .horizontal
        headerRow.alignment = .lastBaseline
        headerRow.spacing = ILMetrics.spaceSmall

        barsStack.axis = .horizontal
        barsStack.alignment = .fill
        barsStack.distribution = .fillEqually
        barsStack.spacing = Layout.barSpacing
        barsStack.heightAnchor.constraint(equalToConstant: Layout.chartHeight).isActive = true

        [startLabel, endLabel].forEach {
            $0.font = ILTypography.microCaption
            $0.textColor = ILColors.inkMuted
        }
        let axisRow = UIStackView(arrangedSubviews: [startLabel, UIView(), endLabel])
        axisRow.axis = .horizontal

        let stack = UIStackView(arrangedSubviews: [headerRow, barsStack, axisRow])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.setCustomSpacing(Layout.chartTopSpacing, after: headerRow)
        stack.setCustomSpacing(Layout.axisTopSpacing, after: barsStack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: Layout.padding),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.padding),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.padding),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.padding)
        ])
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILStatBarChartCardView, _) in
            view.applyColorAppearanceChange()
        }
    }

    /// Each bar is a bottom-aligned column inside an equal-width slot; its height is a fraction of the slot.
    private func rebuildBars() {
        barsStack.arrangedSubviews.forEach {
            barsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for bar in bars {
            let slot = UIView()
            let column = UIView()
            column.backgroundColor = barColor.withAlphaComponent(CGFloat(min(max(bar.opacity, 0), 1)))
            column.layer.cornerRadius = Layout.barTopRadius
            column.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            column.translatesAutoresizingMaskIntoConstraints = false
            slot.addSubview(column)

            NSLayoutConstraint.activate([
                column.leadingAnchor.constraint(equalTo: slot.leadingAnchor),
                column.trailingAnchor.constraint(equalTo: slot.trailingAnchor),
                column.bottomAnchor.constraint(equalTo: slot.bottomAnchor),
                column.heightAnchor.constraint(
                    equalTo: slot.heightAnchor,
                    multiplier: CGFloat(min(max(bar.heightRatio, 0), 1))
                )
            ])
            barsStack.addArrangedSubview(slot)
        }
        isAccessibilityElement = true
        accessibilityLabel = [title, trailingText].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    private func applyColorAppearanceChange() {
        layer.borderColor = ILColors.border.cgColor
    }
}
