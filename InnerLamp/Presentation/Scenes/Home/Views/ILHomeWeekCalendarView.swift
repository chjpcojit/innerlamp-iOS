//
//  ILHomeWeekCalendarView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 27/9/26.
//

import UIKit

/// Dải lịch tuần Trang chủ — nhãn tháng + link "Lịch âm" phía trên, 7 nhãn thứ (Thứ Hai → Chủ nhật,
/// CN đỏ), dải 5 tuần vuốt ngang (2 trước, hiện tại, 2 sau; mở ở tuần hiện tại), bảng chú thích
/// Hoàng đạo / Hắc đạo / Rằm · Mùng Một phía dưới. Chạm 1 ô ngày để chọn (đổi state ô + phát
/// `onSelectDay` để ViewModel cập nhật thẻ âm lịch lớn). Riêng cho Trang chủ nên nằm ở
/// `Scenes/Home`, không phải component dùng chung.
final class ILHomeWeekCalendarView: UIView {

    // MARK: - Layout constants
    private static let dayCellHeight: CGFloat = 62

    // MARK: - Properties
    var weekdayLabels: [String] = [] {
        didSet { rebuildWeekdayHeader() }
    }

    var calendarLinkText: String = "" {
        didSet { calendarLinkButton.setTitle(calendarLinkText, for: .normal) }
    }

    var memorialLinkText: String = "" {
        didSet { memorialLinkButton.setTitle(memorialLinkText, for: .normal) }
    }

    var legend: [ILHomeWeekLegendModel] = [] {
        didSet { rebuildLegend() }
    }

    var pages: [ILHomeWeekPageModel] = [] {
        didSet { rebuildPages() }
    }

    var onCalendarLinkTap: (() -> Void)?
    var onMemorialLinkTap: (() -> Void)?
    var onSelectDay: ((ILHomeWeekDayModel) -> Void)?

    // MARK: - UI Elements
    private lazy var weekLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.bodySmallMedium
        v.textColor = ILColors.ink
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var calendarLinkButton: UIButton = {
        let v = UIButton(type: .system)
        v.titleLabel?.font = ILTypography.subhead
        v.setTitleColor(ILColors.link, for: .normal)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var memorialLinkButton: UIButton = {
        let v = UIButton(type: .system)
        v.titleLabel?.font = ILTypography.subhead
        v.setTitleColor(ILColors.link, for: .normal)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var weekdayRow: UIStackView = {
        let v = UIStackView()
        v.axis = .horizontal
        v.distribution = .fillEqually
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var scrollView: UIScrollView = {
        let v = UIScrollView()
        v.isPagingEnabled = true
        v.showsHorizontalScrollIndicator = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var pageStack: UIStackView = {
        let v = UIStackView()
        v.axis = .horizontal
        v.alignment = .fill
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var legendRow: UIStackView = {
        let v = UIStackView()
        v.axis = .horizontal
        v.spacing = 16
        v.alignment = .center
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// Trang đang hiển thị (index vào `pages`) — dùng để đặt lại offset khi rebuild và để cập nhật
    /// nhãn tháng ở header.
    private var currentPage = 0
    private var didSetInitialPage = false
    /// Trang cần cuộn tới sau khi layout xong (vì contentSize chỉ chính xác sau layout).
    private var pendingPage: Int?

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
        calendarLinkButton.addTarget(self, action: #selector(handleCalendarLinkTap), for: .touchUpInside)
        memorialLinkButton.addTarget(self, action: #selector(handleMemorialLinkTap), for: .touchUpInside)

        let linksRow = UIStackView(arrangedSubviews: [memorialLinkButton, calendarLinkButton])
        linksRow.axis = .horizontal
        linksRow.spacing = ILMetrics.spaceMedium
        linksRow.alignment = .lastBaseline

        let headerRow = UIStackView(arrangedSubviews: [weekLabel, linksRow])
        headerRow.axis = .horizontal
        headerRow.distribution = .equalSpacing
        headerRow.alignment = .lastBaseline
        headerRow.translatesAutoresizingMaskIntoConstraints = false

        scrollView.delegate = self
        scrollView.addSubview(pageStack)

        addSubview(headerRow)
        addSubview(weekdayRow)
        addSubview(scrollView)
        addSubview(legendRow)

        NSLayoutConstraint.activate([
            headerRow.topAnchor.constraint(equalTo: topAnchor),
            headerRow.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerRow.trailingAnchor.constraint(equalTo: trailingAnchor),

            weekdayRow.topAnchor.constraint(equalTo: headerRow.bottomAnchor, constant: 12),
            weekdayRow.leadingAnchor.constraint(equalTo: leadingAnchor),
            weekdayRow.trailingAnchor.constraint(equalTo: trailingAnchor),

            scrollView.topAnchor.constraint(equalTo: weekdayRow.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: Self.dayCellHeight),

            pageStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            pageStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            pageStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            pageStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            pageStack.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),

            legendRow.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 10),
            legendRow.centerXAnchor.constraint(equalTo: centerXAnchor),
            legendRow.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        if let page = pendingPage {
            pendingPage = nil
            scrollToPage(page, animated: false)
        }
    }

    // MARK: - Rebuild helpers
    private func rebuildWeekdayHeader() {
        weekdayRow.arrangedSubviews.forEach {
            weekdayRow.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for (index, label) in weekdayLabels.enumerated() {
            let labelView = UILabel()
            labelView.font = ILTypography.labelMedium
            // Chủ nhật (cột cuối) đỏ, các ngày còn lại mực mờ — khớp `weekHead` trong design handoff.
            labelView.textColor = index == weekdayLabels.count - 1 ? ILColors.inauspicious : ILColors.inkTertiary
            labelView.textAlignment = .center
            labelView.text = label
            weekdayRow.addArrangedSubview(labelView)
        }
    }

    private func rebuildPages() {
        pageStack.arrangedSubviews.forEach {
            pageStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        if !didSetInitialPage {
            currentPage = pages.firstIndex { $0.days.contains(where: \.isToday) } ?? 0
            didSetInitialPage = true
        } else {
            currentPage = min(max(0, currentPage), max(0, pages.count - 1))
        }

        for page in pages {
            let pageView = ILHomeWeekPageView(page: page) { [weak self] day in
                self?.onSelectDay?(day)
            }
            // Add the page to the stack first so it shares a common ancestor with the scroll view
            // before pinning its width. Activating the constraint first throws NSGenericException
            // ("no common ancestor") because the page is not yet in the view hierarchy.
            pageStack.addArrangedSubview(pageView)
            // Mỗi trang rộng đúng bằng khung carousel (paging snap) — dùng frameLayoutGuide để tự
            // theo khi khung đổi, tránh phải cập nhật hằng số thủ công.
            pageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor).isActive = true
        }

        updateHeaderLabel()
        pendingPage = currentPage
        setNeedsLayout()
    }

    private func rebuildLegend() {
        legendRow.arrangedSubviews.forEach {
            legendRow.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for item in legend {
            legendRow.addArrangedSubview(makeLegendItem(item))
        }
    }

    private func makeLegendItem(_ item: ILHomeWeekLegendModel) -> UIView {
        let dot = UIView()
        dot.backgroundColor = dotColor(for: item.dotKind, isSelected: false)
        dot.layer.cornerRadius = 3
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.widthAnchor.constraint(equalToConstant: 6).isActive = true
        dot.heightAnchor.constraint(equalToConstant: 6).isActive = true

        let label = UILabel()
        label.font = ILTypography.caption
        label.textColor = ILColors.inkTertiary
        label.text = item.text

        let itemStack = UIStackView(arrangedSubviews: [dot, label])
        itemStack.axis = .horizontal
        itemStack.spacing = 6
        itemStack.alignment = .center
        return itemStack
    }

    private func updateHeaderLabel() {
        guard pages.indices.contains(currentPage) else { return }
        weekLabel.text = pages[currentPage].label
    }

    /// Cuộn tới trang `page` (0-based).
    private func scrollToPage(_ page: Int, animated: Bool) {
        guard bounds.width > 0 else {
            pendingPage = page
            return
        }
        let target = CGPoint(x: CGFloat(page) * bounds.width, y: 0)
        scrollView.setContentOffset(target, animated: animated)
        currentPage = page
        updateHeaderLabel()
    }

    // MARK: - Actions
    @objc private func handleCalendarLinkTap() {
        onCalendarLinkTap?()
    }

    @objc private func handleMemorialLinkTap() {
        onMemorialLinkTap?()
    }

    /// Màu chấm theo loại ngày — biến thể sáng (onDark) dùng khi ô đang chọn (nền mực tối).
    private func dotColor(for kind: ILHomeWeekDotKind, isSelected: Bool) -> UIColor {
        switch kind {
        case .newMoonFullMoon: return isSelected ? ILColors.goldOnDark : ILColors.goldBright
        case .hoangDao: return isSelected ? ILColors.auspiciousOnDark : ILColors.auspicious
        case .hacDao: return isSelected ? ILColors.inauspiciousOnDark : ILColors.inauspicious
        }
    }
}

// MARK: - UIScrollViewDelegate
extension ILHomeWeekCalendarView: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updatePageAfterScroll()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else { return }
        updatePageAfterScroll()
    }

    private func updatePageAfterScroll() {
        guard bounds.width > 0, !pages.isEmpty else { return }
        let page = min(max(Int((scrollView.contentOffset.x / bounds.width).rounded()), 0), pages.count - 1)
        guard page != currentPage else { return }
        currentPage = page
        updateHeaderLabel()
    }
}

/// 1 trang (tuần) trong `ILHomeWeekCalendarView` — 7 ô ngày trải đều.
private final class ILHomeWeekPageView: UIView {

    private let onTap: (ILHomeWeekDayModel) -> Void

    init(page: ILHomeWeekPageModel, onTap: @escaping (ILHomeWeekDayModel) -> Void) {
        self.onTap = onTap
        super.init(frame: .zero)
        setupViews(page: page)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews(page: ILHomeWeekPageModel) {
        translatesAutoresizingMaskIntoConstraints = false

        let daysStack = UIStackView()
        daysStack.axis = .horizontal
        daysStack.distribution = .fillEqually
        daysStack.spacing = 6
        daysStack.translatesAutoresizingMaskIntoConstraints = false

        for day in page.days {
            let cell = ILHomeWeekDayCellView(day: day)
            cell.onTap = { [weak self] in self?.onTap(day) }
            daysStack.addArrangedSubview(cell)
        }

        addSubview(daysStack)
        NSLayoutConstraint.activate([
            daysStack.topAnchor.constraint(equalTo: topAnchor),
            daysStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            daysStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            daysStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

/// 1 ô ngày trong dải lịch tuần — số ngày dương / số ngày âm / chấm màu (vàng = Rằm·Mùng Một,
/// xanh = Hoàng đạo, đỏ = Hắc đạo). Đổi nền/viền/chữ theo `isToday`/`isSelected` (khớp
/// `d.bg`/`d.bd`/`d.fg`/`d.lfg`/`d.dot` trong design handoff).
private final class ILHomeWeekDayCellView: UIView {

    var onTap: (() -> Void)?

    private lazy var dayLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.beVietnamPro(size: 16, weight: .medium)
        v.text = "\(day.solarDay)"
        v.textAlignment = .center
        return v
    }()
    private lazy var lunarLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.captionSmall
        v.text = day.lunarText
        v.textAlignment = .center
        return v
    }()
    private lazy var dot: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 2.5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var control: UIControl = {
        let v = UIControl()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let day: ILHomeWeekDayModel

    init(day: ILHomeWeekDayModel) {
        self.day = day
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false

        layer.cornerRadius = 16
        layer.borderWidth = 1

        let stack = UIStackView(arrangedSubviews: [dayLabel, lunarLabel, dot])
        stack.axis = .vertical
        stack.spacing = 3
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        control.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        addSubview(control)

        NSLayoutConstraint.activate([
            dot.widthAnchor.constraint(equalToConstant: 5),
            dot.heightAnchor.constraint(equalToConstant: 5),

            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),

            control.leadingAnchor.constraint(equalTo: leadingAnchor),
            control.trailingAnchor.constraint(equalTo: trailingAnchor),
            control.topAnchor.constraint(equalTo: topAnchor),
            control.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        applyState()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILHomeWeekDayCellView, _) in
            view.applyColorAppearanceChange()
        }
    }

    private func applyState() {
        let isSelected = day.isSelected
        let isToday = day.isToday && !isSelected

        if isSelected {
            backgroundColor = ILColors.ink
            layer.borderColor = ILColors.ink.cgColor
        } else if isToday {
            backgroundColor = ILColors.surface
            layer.borderColor = ILColors.borderStrong.cgColor
        } else {
            backgroundColor = .clear
            layer.borderColor = ILColors.border.cgColor
        }

        dayLabel.textColor = isSelected ? ILColors.canvas : ILColors.ink
        lunarLabel.textColor = isSelected ? ILColors.canvasOnInkSecondary : ILColors.inkMuted
        dot.backgroundColor = dotColor(isSelected: isSelected)
    }

    private func dotColor(isSelected: Bool) -> UIColor {
        switch day.dotKind {
        case .newMoonFullMoon: return isSelected ? ILColors.goldOnDark : ILColors.goldBright
        case .hoangDao: return isSelected ? ILColors.auspiciousOnDark : ILColors.auspicious
        case .hacDao: return isSelected ? ILColors.inauspiciousOnDark : ILColors.inauspicious
        }
    }

    private func applyColorAppearanceChange() {
        applyState()
    }

    @objc private func handleTap() {
        onTap?()
    }
}
