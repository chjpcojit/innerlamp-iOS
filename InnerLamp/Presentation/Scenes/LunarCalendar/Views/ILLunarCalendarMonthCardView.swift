//
//  ILLunarCalendarMonthCardView.swift
//  InnerLamp
//

import UIKit

/// Thẻ 1 tháng: hàng thứ (CN...T7) + lưới ngày 7 cột. Mỗi ô hiện số ngày dương lớn và ngày âm
/// nhỏ bên dưới; ô đang chọn đảo nền `ink`, hôm nay nền `canvasWarmEnd1`, ngày trai nền vàng nhạt.
final class ILLunarCalendarMonthCardView: UIView {

    // MARK: - Layout constants
    static let columnCount = 7
    static let maxRowCount = 6
    static let cellSpacing: CGFloat = 4
    static let horizontalPadding: CGFloat = ILMetrics.spaceMedium
    static let verticalPadding: CGFloat = ILMetrics.spaceStandard
    static let weekdayToGridSpacing: CGFloat = ILMetrics.spaceSmall

    /// Chiều cao thẻ khi tháng có đủ 6 hàng — mọi thẻ trong carousel dùng chung chiều cao này.
    static func height(forWidth width: CGFloat) -> CGFloat {
        let innerWidth = width - 2 * horizontalPadding
        let cellSide = (innerWidth - CGFloat(columnCount - 1) * cellSpacing) / CGFloat(columnCount)
        let gridHeight = CGFloat(maxRowCount) * cellSide + CGFloat(maxRowCount - 1) * cellSpacing
        return 2 * verticalPadding + ceil(ILTypography.captionMedium.lineHeight) + weekdayToGridSpacing + gridHeight
    }

    // MARK: - Properties
    var onDayTap: ((String) -> Void)?

    // MARK: - UI Elements
    private let weekdayRow: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = ILLunarCalendarMonthCardView.cellSpacing
        return stack
    }()

    private let gridStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fill
        stack.spacing = ILLunarCalendarMonthCardView.cellSpacing
        return stack
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardLarge
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.resolvedColor(with: traitCollection).cgColor

        [weekdayRow, gridStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        // Chiều cao thẻ do carousel ấn định (đủ chỗ cho 6 hàng); ràng buộc đáy chỉ là chốt an toàn,
        // hạ ưu tiên để sai số làm tròn không sinh cảnh báo Auto Layout.
        let gridBottom = gridStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -Self.verticalPadding)
        gridBottom.priority = UILayoutPriority(999)

        NSLayoutConstraint.activate([
            weekdayRow.topAnchor.constraint(equalTo: topAnchor, constant: Self.verticalPadding),
            weekdayRow.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.horizontalPadding),
            weekdayRow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.horizontalPadding),

            gridStack.topAnchor.constraint(equalTo: weekdayRow.bottomAnchor, constant: Self.weekdayToGridSpacing),
            gridStack.leadingAnchor.constraint(equalTo: weekdayRow.leadingAnchor),
            gridStack.trailingAnchor.constraint(equalTo: weekdayRow.trailingAnchor),
            gridBottom
        ])
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILLunarCalendarMonthCardView, _) in
            view.applyColorAppearanceChange()
        }
    }

    private func applyColorAppearanceChange() {
        layer.borderColor = ILColors.border.resolvedColor(with: traitCollection).cgColor
    }

    // MARK: - Configure
    func configure(month: ILLunarCalendarMonthModel, weekdayLabels: [String]) {
        rebuildWeekdayRow(labels: weekdayLabels)
        rebuildGrid(month: month)
    }

    private func rebuildWeekdayRow(labels: [String]) {
        clear(weekdayRow)
        for text in labels {
            let label = UILabel()
            label.font = ILTypography.captionMedium
            label.textColor = ILColors.inkMuted
            label.textAlignment = .center
            label.text = text
            label.isAccessibilityElement = false
            weekdayRow.addArrangedSubview(label)
        }
    }

    private func rebuildGrid(month: ILLunarCalendarMonthModel) {
        clear(gridStack)

        let dayCells: [ILLunarCalendarDayCellView?] =
            Array(repeating: nil, count: month.leadingBlankDays)
            + month.days.map { day in
                let cell = ILLunarCalendarDayCellView(day: day)
                cell.onTap = { [weak self] in self?.onDayTap?(day.id) }
                return cell
            }

        let columns = Self.columnCount
        let paddedCount = Int((Double(dayCells.count) / Double(columns)).rounded(.up)) * columns

        for rowStart in stride(from: 0, to: paddedCount, by: columns) {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = Self.cellSpacing

            for index in rowStart..<(rowStart + columns) {
                if index < dayCells.count, let cell = dayCells[index] {
                    rowStack.addArrangedSubview(cell)
                } else {
                    rowStack.addArrangedSubview(ILLunarCalendarBlankCellView())
                }
            }
            gridStack.addArrangedSubview(rowStack)
        }
    }

    private func clear(_ stack: UIStackView) {
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }
}

// MARK: - Cells

/// Ô trống đầu/cuối tháng — chỉ giữ chỗ để lưới đủ 7 cột.
private final class ILLunarCalendarBlankCellView: UIView {
    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        isAccessibilityElement = false
        heightAnchor.constraint(equalTo: widthAnchor).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// 1 ô ngày: số dương + số âm + chấm màu (Hoàng đạo/Hắc đạo/Rằm·Mùng Một), nền đổi theo
/// chọn/hôm nay/ngày trai.
private final class ILLunarCalendarDayCellView: UIControl {

    var onTap: (() -> Void)?

    private lazy var solarLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.rowTitle
        return label
    }()

    private lazy var lunarLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.calendarLunarDay
        return label
    }()

    private lazy var dot: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 2
        return view
    }()

    init(day: ILLunarCalendarDayModel) {
        super.init(frame: .zero)
        setupViews(day: day)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews(day: ILLunarCalendarDayModel) {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = ILMetrics.radiusIconTile

        if day.isSelected {
            backgroundColor = ILColors.ink
        } else if day.isToday {
            backgroundColor = ILColors.canvasWarmEnd1
        } else if day.isFastDay {
            backgroundColor = ILColors.goldDayTint
        } else {
            backgroundColor = .clear
        }

        solarLabel.textColor = day.isSelected ? ILColors.canvas : ILColors.ink
        solarLabel.text = day.solarText

        lunarLabel.textColor = day.isSelected ? ILColors.canvasOnInkSecondary : ILColors.link
        lunarLabel.text = day.lunarText

        dot.backgroundColor = dotColor(for: day.dotKind, isSelected: day.isSelected)

        let stack = UIStackView(arrangedSubviews: [solarLabel, lunarLabel, dot])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 1
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalTo: widthAnchor),
            dot.widthAnchor.constraint(equalToConstant: 4),
            dot.heightAnchor.constraint(equalToConstant: 4),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        isAccessibilityElement = true
        accessibilityLabel = "\(day.solarText), \(day.lunarText)"
        accessibilityTraits = day.isSelected ? [.button, .selected] : .button

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    /// Màu chấm theo loại ngày — biến thể sáng (onDark) dùng khi ô đang chọn (nền mực tối).
    private func dotColor(for kind: ILLunarCalendarDayDotKind, isSelected: Bool) -> UIColor {
        switch kind {
        case .newMoonFullMoon: return isSelected ? ILColors.goldOnDark : ILColors.goldBright
        case .hoangDao: return isSelected ? ILColors.auspiciousOnDark : ILColors.auspicious
        case .hacDao: return isSelected ? ILColors.inauspiciousOnDark : ILColors.inauspicious
        }
    }

    @objc private func handleTap() {
        onTap?()
    }
}
