//
//  ILHomeWeekCalendarView.swift
//  InnerLamp
//

import UIKit

/// Dải lịch tuần Trang chủ: nhãn tuần + link "Lịch âm" phía trên, 7 ô ngày (thứ/ngày dương/ngày
/// âm) phía dưới — chạm 1 ô để chọn (chỉ đổi state hiển thị cục bộ, không phát sự kiện nghiệp
/// vụ). Riêng cho Trang chủ nên nằm ở `Scenes/Home`, không phải component dùng chung.
final class ILHomeWeekCalendarView: UIView {

    // MARK: - Properties
    var weekLabelText: String = "" {
        didSet { weekLabel.text = weekLabelText }
    }

    var calendarLinkText: String = "" {
        didSet { calendarLinkButton.setTitle(calendarLinkText, for: .normal) }
    }

    var days: [ILHomeWeekDayModel] = [] {
        didSet { rebuildDays() }
    }

    var onCalendarLinkTap: (() -> Void)?
    var onSelectDay: ((ILHomeWeekDayModel) -> Void)?

    // MARK: - UI Elements
    private let weekLabel = UILabel()
    private let calendarLinkButton = UIButton(type: .system)
    private let daysStack = UIStackView()

    /// id ngày đang chọn — mặc định hôm nay, chỉ là UI state cục bộ (không cần round-trip qua
    /// ViewModel vì chưa có màn "chi tiết theo ngày" để điều hướng tới).
    private var selectedDayID: String?

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        weekLabel.font = ILTypography.sectionTitle
        weekLabel.textColor = ILColors.ink
        weekLabel.translatesAutoresizingMaskIntoConstraints = false

        calendarLinkButton.titleLabel?.font = ILTypography.bodySmall
        calendarLinkButton.setTitleColor(ILColors.goldDeep, for: .normal)
        calendarLinkButton.addTarget(self, action: #selector(handleCalendarLinkTap), for: .touchUpInside)
        calendarLinkButton.translatesAutoresizingMaskIntoConstraints = false

        let headerRow = UIStackView(arrangedSubviews: [weekLabel, calendarLinkButton])
        headerRow.axis = .horizontal
        headerRow.distribution = .equalSpacing
        headerRow.alignment = .lastBaseline
        headerRow.translatesAutoresizingMaskIntoConstraints = false

        daysStack.axis = .horizontal
        daysStack.spacing = 6
        daysStack.distribution = .fillEqually
        daysStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(headerRow)
        addSubview(daysStack)

        NSLayoutConstraint.activate([
            headerRow.topAnchor.constraint(equalTo: topAnchor),
            headerRow.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerRow.trailingAnchor.constraint(equalTo: trailingAnchor),

            daysStack.topAnchor.constraint(equalTo: headerRow.bottomAnchor, constant: 10),
            daysStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            daysStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            daysStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func rebuildDays() {
        daysStack.arrangedSubviews.forEach {
            daysStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        if selectedDayID == nil {
            selectedDayID = days.first(where: { $0.isToday })?.id
        }

        for day in days {
            let cell = ILHomeWeekDayCellView(day: day, isSelected: day.id == selectedDayID)
            cell.onTap = { [weak self] in self?.handleDayTap(day) }
            daysStack.addArrangedSubview(cell)
        }
    }

    private func handleDayTap(_ day: ILHomeWeekDayModel) {
        guard selectedDayID != day.id else { return }
        selectedDayID = day.id
        rebuildDays()
        onSelectDay?(day)
    }

    @objc private func handleCalendarLinkTap() {
        onCalendarLinkTap?()
    }
}

/// 1 ô ngày trong `ILHomeWeekCalendarView` — thứ ngắn / số ngày dương / số ngày âm / chấm trạng
/// thái, đổi nền-viền theo `isToday`/`isSelected` (khớp `d.bg`/`d.bd`/`d.fg` trong design handoff).
private final class ILHomeWeekDayCellView: UIView {

    var onTap: (() -> Void)?

    private let weekdayLabel = UILabel()
    private let dayLabel = UILabel()
    private let lunarLabel = UILabel()
    private let dot = UIView()
    private let control = UIControl()

    private let isToday: Bool
    private let isSelected: Bool

    init(day: ILHomeWeekDayModel, isSelected: Bool) {
        self.isToday = day.isToday
        self.isSelected = isSelected
        super.init(frame: .zero)
        setupViews(day: day)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews(day: ILHomeWeekDayModel) {
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 62).isActive = true

        layer.cornerRadius = 16
        layer.borderWidth = 1
        applyState()

        weekdayLabel.font = ILTypography.captionSmall
        weekdayLabel.text = day.weekdayShort
        weekdayLabel.textAlignment = .center

        dayLabel.font = ILTypography.beVietnamPro(size: 16, weight: .medium)
        dayLabel.text = "\(day.solarDay)"
        dayLabel.textAlignment = .center

        lunarLabel.font = ILTypography.captionSmall
        lunarLabel.text = "\(day.lunarDay)"
        lunarLabel.textAlignment = .center

        dot.backgroundColor = isToday ? ILColors.goldBright : .clear
        dot.layer.cornerRadius = 2
        dot.translatesAutoresizingMaskIntoConstraints = false

        applyTextColors()

        let stack = UIStackView(arrangedSubviews: [weekdayLabel, dayLabel, lunarLabel, dot])
        stack.axis = .vertical
        stack.spacing = 3
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        control.translatesAutoresizingMaskIntoConstraints = false
        control.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        addSubview(control)

        NSLayoutConstraint.activate([
            dot.widthAnchor.constraint(equalToConstant: 4),
            dot.heightAnchor.constraint(equalToConstant: 4),

            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),

            control.leadingAnchor.constraint(equalTo: leadingAnchor),
            control.trailingAnchor.constraint(equalTo: trailingAnchor),
            control.topAnchor.constraint(equalTo: topAnchor),
            control.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func applyState() {
        if isSelected {
            backgroundColor = ILColors.gold.withAlphaComponent(0.14)
            layer.borderColor = ILColors.gold.withAlphaComponent(0.4).cgColor
        } else {
            backgroundColor = .clear
            layer.borderColor = UIColor.clear.cgColor
        }
    }

    private func applyTextColors() {
        let primary = isSelected ? ILColors.goldDeep : ILColors.ink
        weekdayLabel.textColor = isSelected ? ILColors.goldDeep.withAlphaComponent(0.7) : ILColors.inkMuted
        dayLabel.textColor = primary
        lunarLabel.textColor = isSelected ? ILColors.goldDeep.withAlphaComponent(0.7) : ILColors.inkMuted
    }

    @objc private func handleTap() {
        onTap?()
    }
}
