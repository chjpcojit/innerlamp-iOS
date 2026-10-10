//
//  ILProfileMenuCardView.swift
//  InnerLamp
//

import UIKit

/// Nhóm 7 hàng điều hướng có icon cuối màn Tôi (Gia phả dòng họ / Tạo gia phả mới / Chuông tỉnh thức /
/// Sổ công đức / Cài đặt / Thông báo / Chùa tu tập) trong 1 thẻ bo góc. Là composition riêng của
/// màn Tôi từ `ILSettingRow` dùng chung.
final class ILProfileMenuCardView: UIView {

    // MARK: - Properties
    var onFamilyTreeTapped: (() -> Void)?
    var onCreateFamilyTreeTapped: (() -> Void)?
    var onReminderTapped: (() -> Void)?
    var onMeritBookTapped: (() -> Void)?
    var onSettingsTapped: (() -> Void)?
    var onNotificationsTapped: (() -> Void)?
    var onCommunityTapped: (() -> Void)?

    // MARK: - UI Elements
    private lazy var familyTreeRow = ILSettingRow(
        title: "profile.menu.familyTree".localized,
        kind: .value,
        icon: ILIcons.rowTree
    )

    private lazy var createFamilyTreeRow = ILSettingRow(
        title: "profile.menu.createFamilyTree".localized,
        kind: .value,
        icon: ILIcons.rowPlus
    )

    private lazy var reminderRow = ILSettingRow(
        title: "profile.menu.reminder".localized,
        kind: .value,
        icon: ILIcons.rowBell
    )

    private lazy var meritBookRow = ILSettingRow(
        title: "profile.menu.meritBook".localized,
        kind: .chevron,
        icon: ILIcons.rowJournal
    )

    private lazy var settingsRow = ILSettingRow(
        title: "profile.menu.settings".localized,
        kind: .chevron,
        icon: ILIcons.rowGear
    )

    private lazy var notificationsRow = ILSettingRow(
        title: "profile.menu.notifications".localized,
        kind: .chevron,
        icon: ILIcons.rowNotif
    )

    private lazy var communityRow = ILSettingRow(
        title: "profile.menu.community".localized,
        kind: .value,
        isLast: true,
        icon: ILIcons.rowTemple
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

        let stack = UIStackView(arrangedSubviews: [
            familyTreeRow, createFamilyTreeRow, reminderRow, meritBookRow, settingsRow, notificationsRow, communityRow
        ])
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

        familyTreeRow.onTap = { [weak self] in self?.onFamilyTreeTapped?() }
        createFamilyTreeRow.onTap = { [weak self] in self?.onCreateFamilyTreeTapped?() }
        reminderRow.onTap = { [weak self] in self?.onReminderTapped?() }
        meritBookRow.onTap = { [weak self] in self?.onMeritBookTapped?() }
        settingsRow.onTap = { [weak self] in self?.onSettingsTapped?() }
        notificationsRow.onTap = { [weak self] in self?.onNotificationsTapped?() }
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
