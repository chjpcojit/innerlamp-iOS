//
//  ILSettingsScheduleCardView.swift
//  InnerLamp
//

import UIKit

/// Nhóm "Thời khóa" màn Cài đặt: 3 hàng (Chuông tỉnh thức switch, Nhắc ngày trai & rằm switch,
/// Tiếng chuông value) trong 1 thẻ bo góc. Composition riêng của màn Cài đặt từ `ILSettingRow`.
final class ILSettingsScheduleCardView: UIView {

    // MARK: - Properties
    var onBellToggle: ((Bool) -> Void)?
    var onFastDayToggle: ((Bool) -> Void)?
    var onBellSoundTap: (() -> Void)?

    // MARK: - UI Elements
    private lazy var bellRow = ILSettingRow(
        title: "settings.row.bell".localized,
        kind: .switch
    )

    private lazy var fastDayRow = ILSettingRow(
        title: "settings.row.fastDay".localized,
        subtitle: "settings.row.fastDay.sub".localized,
        kind: .switch
    )

    private lazy var bellSoundRow = ILSettingRow(
        title: "settings.row.bellSound".localized,
        kind: .value,
        isLast: true
    )

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
        applyDynamicColors()
        registerForAppearanceChanges()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardSmall + 2
        layer.borderWidth = 1
        clipsToBounds = true

        let stack = UIStackView(arrangedSubviews: [bellRow, fastDayRow, bellSoundRow])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        bellRow.onSwitchToggled = { [weak self] value in self?.onBellToggle?(value) }
        fastDayRow.onSwitchToggled = { [weak self] value in self?.onFastDayToggle?(value) }
        bellSoundRow.onTap = { [weak self] in self?.onBellSoundTap?() }
    }

    // MARK: - Configure
    func configure(bellEnabled: Bool, bellScheduleText: String, fastDayReminderEnabled: Bool, bellSoundTitle: String) {
        bellRow.isOn = bellEnabled
        bellRow.subtitle = bellScheduleText
        fastDayRow.isOn = fastDayReminderEnabled
        bellSoundRow.valueText = bellSoundTitle
    }

    private func applyDynamicColors() {
        layer.borderColor = ILColors.border.cgColor
    }

    private func registerForAppearanceChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.applyDynamicColors()
        }
    }
}
