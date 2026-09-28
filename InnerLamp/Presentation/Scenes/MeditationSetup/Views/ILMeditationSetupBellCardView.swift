//
//  ILMeditationSetupBellCardView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import UIKit

/// Nhóm "CHUÔNG" màn Chuẩn bị thiền: 3 hàng chỉ hiển thị giá trị (Chuông mở đầu, Chuông giữa giờ,
/// Nền âm thanh) trong 1 thẻ bo góc. Composition riêng của màn này từ `ILSettingRow` (kind `.value`),
/// không tương tác — khớp `IL-SettingRow kind="value"` trong design handoff.
final class ILMeditationSetupBellCardView: UIView {

    // MARK: - UI Elements
    private lazy var openingBellRow = ILSettingRow(
        title: "meditationSetup.bell.opening.title".localized,
        kind: .value
    )

    private lazy var intervalBellRow = ILSettingRow(
        title: "meditationSetup.bell.interval.title".localized,
        kind: .value
    )

    private lazy var backgroundSoundRow = ILSettingRow(
        title: "meditationSetup.bell.sound.title".localized,
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

        let stack = UIStackView(arrangedSubviews: [openingBellRow, intervalBellRow, backgroundSoundRow])
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
    }

    // MARK: - Configure
    func configure(openingValue: String, intervalValue: String, soundValue: String) {
        openingBellRow.valueText = openingValue
        intervalBellRow.valueText = intervalValue
        backgroundSoundRow.valueText = soundValue
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
