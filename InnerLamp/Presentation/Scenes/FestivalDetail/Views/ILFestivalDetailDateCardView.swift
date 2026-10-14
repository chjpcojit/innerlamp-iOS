//
//  ILFestivalDetailDateCardView.swift
//  InnerLamp
//

import UIKit

/// EN: Solar-date card of the festival detail screen: big day number, "weekday, month, year" with a
///     caption, and a countdown pill on the trailing side.
/// VI: Thẻ ngày dương của màn "Chi tiết ngày lễ": số ngày lớn, "Thứ X, Tháng M, YYYY" + chú thích,
///     và viên thuốc đếm ngược bên phải.
final class ILFestivalDetailDateCardView: UIView {

    private enum Layout {
        static let verticalInset: CGFloat = 16
        static let horizontalInset: CGFloat = 18
        static let dayColumnWidth: CGFloat = 58
        static let spacing: CGFloat = 16
        static let pillVerticalInset: CGFloat = 6
        static let pillHorizontalInset: CGFloat = 11
        // EN: Pill sits closer to the card's trailing edge than the text content does.
        // VI: Viên thuốc nằm sát lề phải của thẻ hơn phần nội dung chữ.
        static let pillTrailingInset: CGFloat = 10
    }

    // MARK: - UI Elements
    private lazy var dayLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.displayLarge
        label.textColor = ILColors.link
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.sectionTitle
        label.textColor = ILColors.ink
        label.numberOfLines = 0
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }()

    private lazy var captionLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.label
        label.textColor = ILColors.inkTertiary
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }()

    private lazy var countdownLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.chip
        label.textColor = ILColors.link
        // EN: Hug the text so the pill never stretches (default 250 tied with the text column → slack landed here).
        // VI: Ôm sát chữ để viên thuốc không bị giãn (mặc định 250 bằng cột chữ → phần dư rơi vào đây).
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var divider: UIView = {
        let view = UIView()
        view.backgroundColor = ILColors.border
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var dayColumn: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var textStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [dateLabel, captionLabel])
        stack.axis = .vertical
        stack.spacing = ILMetrics.spaceTiny
        // EN: Text column absorbs all slack so the countdown pill is pushed to the trailing edge.
        // VI: Cột chữ nhận hết phần dư để viên thuốc đếm ngược bị đẩy sát lề phải.
        stack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var pill: UIView = {
        let view = UIView()
        view.backgroundColor = ILColors.goldDayTint
        // EN: Gold hairline so the pill reads as a child block inside the bordered card (light + dark).
        // VI: Viền vàng mảnh để viên thuốc hiện rõ là khối con trong thẻ có viền (light + dark).
        view.layer.borderWidth = ILMetrics.hairline
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration
    func configure(day: String, date: String, caption: String, countdown: String) {
        dayLabel.text = day
        dateLabel.text = date
        captionLabel.text = caption
        countdownLabel.text = countdown
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardRegular
        layer.borderWidth = ILMetrics.hairline

        [dayLabel, divider].forEach { dayColumn.addSubview($0) }
        pill.addSubview(countdownLabel)
        [dayColumn, textStack, pill].forEach { addSubview($0) }

        NSLayoutConstraint.activate([
            // EN: Pill is pinned to its own (tighter) trailing inset; the text column fills what is left of it.
            // VI: Viên thuốc ghim vào lề phải riêng (hẹp hơn); cột chữ lấp phần còn lại.
            dayColumn.topAnchor.constraint(equalTo: topAnchor, constant: Layout.verticalInset),
            dayColumn.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.verticalInset),
            dayColumn.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalInset),
            textStack.leadingAnchor.constraint(equalTo: dayColumn.trailingAnchor, constant: Layout.spacing),
            textStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            textStack.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: Layout.verticalInset),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -Layout.verticalInset),
            pill.leadingAnchor.constraint(equalTo: textStack.trailingAnchor, constant: Layout.spacing),
            pill.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.pillTrailingInset),
            pill.centerYAnchor.constraint(equalTo: centerYAnchor),

            dayColumn.widthAnchor.constraint(equalToConstant: Layout.dayColumnWidth),
            dayLabel.topAnchor.constraint(equalTo: dayColumn.topAnchor),
            dayLabel.bottomAnchor.constraint(equalTo: dayColumn.bottomAnchor),
            dayLabel.leadingAnchor.constraint(equalTo: dayColumn.leadingAnchor),
            dayLabel.trailingAnchor.constraint(equalTo: divider.leadingAnchor, constant: -Layout.spacing + ILMetrics.hairline),
            divider.topAnchor.constraint(equalTo: dayColumn.topAnchor),
            divider.bottomAnchor.constraint(equalTo: dayColumn.bottomAnchor),
            divider.trailingAnchor.constraint(equalTo: dayColumn.trailingAnchor),
            divider.widthAnchor.constraint(equalToConstant: ILMetrics.hairline),

            countdownLabel.topAnchor.constraint(equalTo: pill.topAnchor, constant: Layout.pillVerticalInset),
            countdownLabel.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -Layout.pillVerticalInset),
            countdownLabel.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: Layout.pillHorizontalInset),
            countdownLabel.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -Layout.pillHorizontalInset)
        ])

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILFestivalDetailDateCardView, _) in
            view.applyBorderColor()
        }
    }

    // EN: `layer.borderColor` is a static CGColor — resolve it against the live trait (the init-time
    //     value is resolved while detached, i.e. as light, so the border vanished in dark mode).
    // VI: `layer.borderColor` là CGColor tĩnh — resolve theo trait hiện tại (lúc init view chưa gắn
    //     vào window nên ra màu light, viền gần như mất ở dark mode).
    private func applyBorderColor() {
        layer.borderColor = ILColors.border.resolvedColor(with: traitCollection).cgColor
        // EN: Solid link color — `goldBorder` (45% gold) disappeared against the pill's gold tint.
        // VI: Màu link đặc — `goldBorder` (vàng 45%) bị chìm vào nền vàng nhạt của viên thuốc.
        pill.layer.borderColor = ILColors.link.resolvedColor(with: traitCollection).cgColor
    }

    // EN: Capsule radius from the real height — `radiusPill` (999) far exceeds half the pill height and
    //     the layer drew neither its fill nor its border on device.
    // VI: Bán kính viên con nhộng theo chiều cao thật — `radiusPill` (999) vượt xa nửa chiều cao viên nên
    //     layer không vẽ được nền lẫn viền trên máy.
    override func layoutSubviews() {
        super.layoutSubviews()
        pill.layer.cornerRadius = pill.bounds.height / 2
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        applyBorderColor()
    }
}
