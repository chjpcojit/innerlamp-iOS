//
//  ILHomeEventsCarouselView.swift
//  InnerLamp
//

import UIKit

/// Carousel "Sự kiện Phật giáo" ở Trang chủ: cuộn ngang từng thẻ tháng (mỗi thẻ liệt kê vài sự
/// kiện), chấm phân trang phía dưới. Riêng cho Trang chủ nên nằm ở `Scenes/Home`, không phải
/// component dùng chung (khác `events` — màn danh sách sự kiện đầy đủ, chưa có trong scope).
final class ILHomeEventsCarouselView: UIView {

    // MARK: - Layout constants
    /// Card rộng 84% khung carousel để lộ mép thẻ tháng kế bên (peek).
    private static let cardWidthRatio: CGFloat = 0.84
    private static let cardSpacing: CGFloat = 12

    // MARK: - Properties
    var months: [ILHomeEventMonthModel] = [] {
        didSet { rebuildCards() }
    }

    var onEventTap: ((ILHomeEventItemModel) -> Void)?

    /// Bề rộng 1 thẻ theo khung hiện tại; dùng chung cho cả lúc dựng thẻ lẫn lúc tính snap.
    private var cardWidth: CGFloat { (bounds.width * Self.cardWidthRatio).rounded(.down) }
    /// Khoảng cách giữa 2 mép trái liên tiếp = bề rộng thẻ + spacing.
    private var pageStride: CGFloat { cardWidth + Self.cardSpacing }

    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let cardsStack = UIStackView()
    private let dotsStack = UIStackView()
    private var cardWidthConstraints: [NSLayoutConstraint] = []
    private var currentPage = 0

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
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.decelerationRate = .fast
        scrollView.delegate = self
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        cardsStack.axis = .horizontal
        cardsStack.spacing = Self.cardSpacing
        cardsStack.alignment = .top
        cardsStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(cardsStack)

        dotsStack.axis = .horizontal
        dotsStack.spacing = 6
        dotsStack.alignment = .center
        dotsStack.distribution = .equalCentering
        dotsStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(scrollView)
        addSubview(dotsStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),

            cardsStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            cardsStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            cardsStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            cardsStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            cardsStack.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),

            dotsStack.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 11),
            dotsStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            dotsStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = cardWidth
        guard width > 0 else { return }
        // Inset phải đủ lớn để tháng cuối cũng snap được về mép trái (offset tối đa = (n-1) * pageStride).
        // Thiếu inset này thì trang cuối bị kẹp ở offset tối đa và lệch khỏi vị trí snap.
        scrollView.contentInset.right = max(0, bounds.width - width)
        for constraint in cardWidthConstraints where constraint.constant != width {
            constraint.constant = width
        }
    }

    private func rebuildCards() {
        cardsStack.arrangedSubviews.forEach {
            cardsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        cardWidthConstraints.removeAll()
        currentPage = 0
        scrollView.setContentOffset(.zero, animated: false)

        let width = max(cardWidth, 1)
        for month in months {
            let card = ILHomeEventMonthCardView(month: month)
            card.onEventTap = { [weak self] event in self?.onEventTap?(event) }
            let widthConstraint = card.widthAnchor.constraint(equalToConstant: width)
            widthConstraint.isActive = true
            cardWidthConstraints.append(widthConstraint)
            cardsStack.addArrangedSubview(card)
        }

        rebuildDots()
    }

    private func rebuildDots() {
        dotsStack.arrangedSubviews.forEach {
            dotsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        guard months.count > 1 else { return }
        for index in months.indices {
            let dot = UIView()
            dot.layer.cornerRadius = 2.5
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.widthAnchor.constraint(equalToConstant: index == currentPage ? 16 : 5).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 5).isActive = true
            dot.backgroundColor = index == currentPage ? ILColors.goldDeep : ILColors.borderStrong
            dotsStack.addArrangedSubview(dot)
        }
    }
}

// MARK: - UIScrollViewDelegate
extension ILHomeEventsCarouselView: UIScrollViewDelegate {
    /// Snap từng thẻ: tối đa 1 trang mỗi lần vuốt dù vận tốc lớn, tránh nhảy nhiều tháng khi
    /// người dùng vuốt nhanh.
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let stride = pageStride
        guard stride > 0, !months.isEmpty else { return }
        let current = page(forOffset: scrollView.contentOffset.x)
        let projected = page(forOffset: targetContentOffset.pointee.x)
        let target = min(max(projected, current - 1), current + 1)
        targetContentOffset.pointee = CGPoint(x: CGFloat(target) * stride, y: 0)
        guard target != currentPage else { return }
        currentPage = target
        rebuildDots()
    }

    /// Trang gần nhất ứng với `offset`, luôn kẹp trong khoảng thẻ hợp lệ.
    private func page(forOffset offset: CGFloat) -> Int {
        guard pageStride > 0, !months.isEmpty else { return 0 }
        let raw = Int((offset / pageStride).rounded())
        return min(max(raw, 0), months.count - 1)
    }
}

/// 1 thẻ tháng trong `ILHomeEventsCarouselView` — tiêu đề tháng + số sự kiện, danh sách sự kiện
/// (ngày/thứ + tiêu đề + nhãn âm lịch).
private final class ILHomeEventMonthCardView: UIView {

    var onEventTap: ((ILHomeEventItemModel) -> Void)?

    private let month: ILHomeEventMonthModel

    init(month: ILHomeEventMonthModel) {
        self.month = month
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardSmall + 4
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor

        let monthLabel = UILabel()
        monthLabel.font = ILTypography.bodySmallMedium
        monthLabel.textColor = ILColors.ink
        monthLabel.text = month.monthLabel

        let countLabel = UILabel()
        countLabel.font = ILTypography.caption
        countLabel.textColor = ILColors.inkMuted
        countLabel.text = String(format: "home.events.countFormat".localized, month.events.count)

        let headerRow = UIStackView(arrangedSubviews: [monthLabel, countLabel])
        headerRow.axis = .horizontal
        headerRow.distribution = .equalSpacing
        headerRow.alignment = .firstBaseline
        headerRow.translatesAutoresizingMaskIntoConstraints = false

        let eventsStack = UIStackView()
        eventsStack.axis = .vertical
        eventsStack.spacing = 0
        eventsStack.translatesAutoresizingMaskIntoConstraints = false

        for (index, event) in month.events.enumerated() {
            if index > 0 {
                let divider = UIView()
                divider.backgroundColor = ILColors.border
                divider.translatesAutoresizingMaskIntoConstraints = false
                divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
                eventsStack.addArrangedSubview(divider)
            }
            let row = ILHomeEventRowView(event: event)
            row.onTap = { [weak self] in self?.onEventTap?(event) }
            eventsStack.addArrangedSubview(row)
        }

        addSubview(headerRow)
        addSubview(eventsStack)

        NSLayoutConstraint.activate([
            headerRow.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            headerRow.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            headerRow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            eventsStack.topAnchor.constraint(equalTo: headerRow.bottomAnchor, constant: 10),
            eventsStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            eventsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            eventsStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
        ])
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        layer.borderColor = ILColors.border.cgColor
    }
}

/// 1 hàng sự kiện trong `ILHomeEventMonthCardView`.
private final class ILHomeEventRowView: UIView {

    var onTap: (() -> Void)?

    init(event: ILHomeEventItemModel) {
        super.init(frame: .zero)
        setupViews(event: event)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews(event: ILHomeEventItemModel) {
        translatesAutoresizingMaskIntoConstraints = false

        let dayLabel = UILabel()
        dayLabel.font = ILTypography.beVietnamPro(size: 16, weight: .medium)
        dayLabel.textColor = event.tone.accentColor
        dayLabel.text = event.dayNumber
        dayLabel.textAlignment = .center

        let weekdayLabel = UILabel()
        weekdayLabel.font = ILTypography.captionSmall
        weekdayLabel.textColor = ILColors.inkMuted
        weekdayLabel.text = event.weekdayLabel
        weekdayLabel.textAlignment = .center

        let dateColumn = UIStackView(arrangedSubviews: [dayLabel, weekdayLabel])
        dateColumn.axis = .vertical
        dateColumn.spacing = 2
        dateColumn.alignment = .center
        dateColumn.translatesAutoresizingMaskIntoConstraints = false
        dateColumn.widthAnchor.constraint(equalToConstant: 40).isActive = true

        let titleLabel = UILabel()
        titleLabel.font = ILTypography.body
        titleLabel.textColor = ILColors.ink
        titleLabel.text = event.title
        titleLabel.numberOfLines = 2

        let lunarLabel = UILabel()
        lunarLabel.font = ILTypography.caption
        lunarLabel.textColor = ILColors.inkTertiary
        lunarLabel.text = event.lunarLabel
        lunarLabel.numberOfLines = 1

        let textColumn = UIStackView(arrangedSubviews: [titleLabel, lunarLabel])
        textColumn.axis = .vertical
        textColumn.spacing = 3
        textColumn.translatesAutoresizingMaskIntoConstraints = false

        let row = UIStackView(arrangedSubviews: [dateColumn, textColumn])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        row.isUserInteractionEnabled = false
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        let control = UIControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        control.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        addSubview(control)

        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor, constant: 9),
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -9),

            control.leadingAnchor.constraint(equalTo: leadingAnchor),
            control.trailingAnchor.constraint(equalTo: trailingAnchor),
            control.topAnchor.constraint(equalTo: topAnchor),
            control.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @objc private func handleTap() {
        onTap?()
    }
}

/// Map `ILHomeEventTone` (Domain) sang màu accent hiển thị — chỉ dùng trong carousel sự kiện
/// nên đặt private ở đây, không chung với `ILColors.Tone` (vốn có thêm case `.ink` không khớp).
private extension ILHomeEventTone {
    var accentColor: UIColor {
        switch self {
        case .gold: return ILColors.goldDeep
        case .green: return ILColors.greenText
        case .rose: return ILColors.roseText
        }
    }
}
