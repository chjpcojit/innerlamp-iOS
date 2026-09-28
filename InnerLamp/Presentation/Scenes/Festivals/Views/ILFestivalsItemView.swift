//
//  ILFestivalsItemView.swift
//  InnerLamp
//

import UIKit

/// 1 thẻ ngày lễ trong màn "Lịch lễ Phật giáo": ô ngày + thứ, tiêu đề + đếm ngược, dòng âm lịch,
/// và hàng chip chùa tổ chức. Biết `ILFestivalDayModel` nên thuộc riêng màn Lịch lễ.
final class ILFestivalsItemView: UIView {

    // MARK: - Constants
    private enum Layout {
        static let tileWidth: CGFloat = 44
        static let padding: CGFloat = 14
        static let gap: CGFloat = 14
        /// `gap: 6px` of the wrapping host-chip row.
        static let hostSpacing: CGFloat = 6
        /// Weekday caption tracking (`letter-spacing: .08em`).
        static let weekdayTrackingEm: CGFloat = 0.08
    }

    /// Chạm 1 chip chùa — mang theo id chùa.
    var onHostTap: ((String) -> Void)?

    // MARK: - UI Elements
    private let cardView = UIView()
    private var isToday = false

    private lazy var dayLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.scriptureBodyLarge
        label.textAlignment = .center
        return label
    }()

    private lazy var weekdayLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.bodyMedium
        label.textColor = ILColors.ink
        label.numberOfLines = 0
        return label
    }()

    private lazy var countdownLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.captionMedium
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private lazy var lunarLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.label
        label.textColor = ILColors.inkSubtle
        label.numberOfLines = 0
        return label
    }()

    /// Host chips + "+N chùa" wrap onto new lines when they overflow (`flex-wrap: wrap`).
    private let hostsFlow = ILChipFlowView(rowSpacing: Layout.hostSpacing, itemSpacing: Layout.hostSpacing)

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
        registerForAppearanceChanges()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = ILColors.surface
        cardView.layer.cornerRadius = ILMetrics.radiusCardSmall
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = ILColors.border.cgColor
        addSubview(cardView)

        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        weekdayLabel.translatesAutoresizingMaskIntoConstraints = false
        let dateColumn = UIStackView(arrangedSubviews: [dayLabel, weekdayLabel])
        dateColumn.axis = .vertical
        dateColumn.spacing = 2
        dateColumn.alignment = .center
        dateColumn.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        let titleRow = UIStackView(arrangedSubviews: [titleLabel, countdownLabel])
        titleRow.axis = .horizontal
        titleRow.alignment = .center
        titleRow.spacing = 8

        lunarLabel.translatesAutoresizingMaskIntoConstraints = false

        let textStack = UIStackView(arrangedSubviews: [titleRow, lunarLabel, hostsFlow])
        textStack.axis = .vertical
        // `.fill` so the flow view gets the full text-column width to wrap against.
        textStack.alignment = .fill
        textStack.spacing = 3
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.setCustomSpacing(10, after: lunarLabel)

        let contentRow = UIStackView(arrangedSubviews: [dateColumn, textStack])
        contentRow.axis = .horizontal
        contentRow.alignment = .top
        contentRow.spacing = Layout.gap
        contentRow.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(contentRow)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: topAnchor),
            cardView.bottomAnchor.constraint(equalTo: bottomAnchor),
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor),

            dateColumn.widthAnchor.constraint(equalToConstant: Layout.tileWidth),

            contentRow.topAnchor.constraint(equalTo: cardView.topAnchor, constant: Layout.padding),
            contentRow.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -Layout.padding),
            contentRow.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: Layout.padding),
            contentRow.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -Layout.padding)
        ])
    }

    // MARK: - Configure
    func configure(with model: ILFestivalDayModel) {
        dayLabel.text = model.dayNumber
        dayLabel.textColor = model.isFestival ? ILColors.link : ILColors.ink
        weekdayLabel.attributedText = ILTypography.makeAttributedString(
            text: model.weekdayLabel,
            font: ILTypography.captionSmall,
            color: ILColors.inkSubtle,
            letterSpacingEm: Layout.weekdayTrackingEm,
            alignment: .center
        )

        titleLabel.text = model.title
        countdownLabel.text = model.countdownText
        countdownLabel.textColor = model.isImminent ? ILColors.link : ILColors.inkSubtle

        lunarLabel.text = model.lunarSubtitle

        isToday = model.isToday
        applyBorder()

        rebuildHosts(model.hosts, moreText: model.moreHostsText)
    }

    private func applyBorder() {
        cardView.layer.borderColor = (isToday ? ILColors.goldBright : ILColors.border).cgColor
    }

    private func rebuildHosts(_ hosts: [ILFestivalHostModel], moreText: String?) {
        var items: [UIView] = hosts.map { host in
            let chip = ILFestivalsHostChipView(title: host.name)
            chip.onTap = { [weak self] in self?.onHostTap?(host.id) }
            return chip
        }
        if let moreText {
            items.append(makeMoreLabel(moreText))
        }
        hostsFlow.setItems(items)
    }

    /// "+N chùa" — same height as a host chip so it sits vertically centered on the chip row
    /// (`align-items: center`); `UILabel` centers its text vertically within that height.
    private func makeMoreLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.font = ILTypography.label
        label.textColor = ILColors.inkSubtle
        label.text = text
        label.translatesAutoresizingMaskIntoConstraints = false
        label.heightAnchor.constraint(equalToConstant: ILFestivalsHostChipView.height).isActive = true
        return label
    }

    private func registerForAppearanceChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILFestivalsItemView, _) in
            view.applyBorder()
        }
    }
}
