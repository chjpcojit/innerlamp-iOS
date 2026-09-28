//
//  ILSettingsPrivacyCardView.swift
//  InnerLamp
//

import UIKit

/// Nhóm "Riêng tư" màn Cài đặt: 2 hàng (Ẩn nhật ký khỏi đạo tràng switch, Tải dữ liệu tu tập của
/// tôi chevron). Composition riêng của màn Cài đặt từ `ILSettingRow`.
final class ILSettingsPrivacyCardView: UIView {

    // MARK: - Properties
    var onHideJournalToggle: ((Bool) -> Void)?
    var onExportTap: (() -> Void)?

    // MARK: - UI Elements
    private lazy var hideJournalRow = ILSettingRow(
        title: "settings.row.hideJournal".localized,
        subtitle: "settings.row.hideJournal.sub".localized,
        kind: .switch
    )

    private lazy var exportRow = ILSettingRow(
        title: "settings.row.export".localized,
        kind: .chevron,
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

        let stack = UIStackView(arrangedSubviews: [hideJournalRow, exportRow])
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

        hideJournalRow.onSwitchToggled = { [weak self] value in self?.onHideJournalToggle?(value) }
        exportRow.onTap = { [weak self] in self?.onExportTap?() }
    }

    // MARK: - Configure
    func configure(hideJournalFromSangha: Bool) {
        hideJournalRow.isOn = hideJournalFromSangha
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
