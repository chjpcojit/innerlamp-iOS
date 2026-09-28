//
//  ILEditProfileVisibilityCardView.swift
//  InnerLamp
//

import UIKit

/// "Hiển thị trong đạo tràng" group of the Edit Profile screen: 3 value rows (Chuỗi ngày tinh tấn,
/// Nhật ký tu tập, Lịch sử cúng dường) showing the current visibility of each. Screen-specific
/// composition of `ILSettingRow`.
final class ILEditProfileVisibilityCardView: UIView {

    // MARK: - Properties
    var onItemTap: ((ILEditProfileVisibilityItem) -> Void)?

    // MARK: - UI Elements
    private lazy var streakRow = ILSettingRow(
        title: "editProfile.visibility.streak".localized,
        kind: .value
    )

    private lazy var journalRow = ILSettingRow(
        title: "editProfile.visibility.journal".localized,
        kind: .value
    )

    private lazy var offeringRow = ILSettingRow(
        title: "editProfile.visibility.offeringHistory".localized,
        kind: .value,
        isLast: true
    )

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
        applyDynamicColors()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.applyDynamicColors()
        }
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

        let stack = UIStackView(arrangedSubviews: [streakRow, journalRow, offeringRow])
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

        streakRow.onTap = { [weak self] in self?.onItemTap?(.streak) }
        journalRow.onTap = { [weak self] in self?.onItemTap?(.journal) }
        offeringRow.onTap = { [weak self] in self?.onItemTap?(.offeringHistory) }
    }

    // MARK: - Configure
    func configure(streakTitle: String, journalTitle: String, offeringHistoryTitle: String) {
        streakRow.valueText = streakTitle
        journalRow.valueText = journalTitle
        offeringRow.valueText = offeringHistoryTitle
    }

    private func applyDynamicColors() {
        layer.borderColor = ILColors.border.cgColor
    }
}
