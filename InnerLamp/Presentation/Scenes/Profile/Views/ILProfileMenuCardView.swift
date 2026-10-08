//
//  ILProfileMenuCardView.swift
//  InnerLamp
//

import UIKit

/// Nhóm 5 hàng điều hướng cuối màn Tôi (Chuông tỉnh thức / Cài đặt / Thông báo / Gia phả / Đạo
/// tràng của tôi) trong 1 thẻ bo góc. Là composition riêng của màn Tôi từ `ILSettingRow` dùng chung.
final class ILProfileMenuCardView: UIView {

    // MARK: - Properties
    var onReminderTapped: (() -> Void)?
    var onSettingsTapped: (() -> Void)?
    var onNotificationsTapped: (() -> Void)?
    var onFamilyTreeTapped: (() -> Void)?
    var onCommunityTapped: (() -> Void)?

    // MARK: - UI Elements
    private lazy var reminderRow = ILSettingRow(
        title: "profile.menu.reminder".localized,
        kind: .value
    )

    private lazy var settingsRow = ILSettingRow(
        title: "profile.menu.settings".localized,
        kind: .chevron
    )

    private lazy var notificationsRow = ILSettingRow(
        title: "profile.menu.notifications".localized,
        kind: .chevron
    )

    private lazy var familyTreeRow = ILSettingRow(
        title: "profile.menu.familyTree".localized,
        kind: .chevron
    )

    private lazy var communityRow = ILSettingRow(
        title: "profile.menu.community".localized,
        kind: .value,
        isLast: true
    )

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
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardSmall + 2
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor
        clipsToBounds = true

        let stack = UIStackView(arrangedSubviews: [reminderRow, settingsRow, notificationsRow, familyTreeRow, communityRow])
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

        reminderRow.onTap = { [weak self] in self?.onReminderTapped?() }
        settingsRow.onTap = { [weak self] in self?.onSettingsTapped?() }
        notificationsRow.onTap = { [weak self] in self?.onNotificationsTapped?() }
        familyTreeRow.onTap = { [weak self] in self?.onFamilyTreeTapped?() }
        communityRow.onTap = { [weak self] in self?.onCommunityTapped?() }
    }

    // MARK: - Configure
    func configure(reminderValue: String, communityValue: String) {
        reminderRow.valueText = reminderValue
        communityRow.valueText = communityValue
    }

    // `layer.borderColor` là CGColor tĩnh, không tự đảo theo trait — refresh thủ công khi đổi
    // light/dark.
    private func registerForAppearanceChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.layer.borderColor = ILColors.border.cgColor
        }
    }
}
