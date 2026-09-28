//
//  ILSettingsContentCardView.swift
//  InnerLamp
//

import UIKit

/// Nhóm "Nội dung & trợ giúp" màn Cài đặt: 3 hàng chevron (Nghe không cần mạng, Ngôn ngữ & hiển
/// thị, Trợ giúp & câu hỏi thường gặp). Composition riêng của màn Cài đặt từ `ILSettingRow`.
final class ILSettingsContentCardView: UIView {

    // MARK: - Properties
    var onDownloadsTap: (() -> Void)?
    var onLanguageTap: (() -> Void)?
    var onHelpTap: (() -> Void)?

    // MARK: - UI Elements
    private lazy var downloadsRow = ILSettingRow(
        title: "settings.row.downloads".localized,
        kind: .chevron
    )

    private lazy var languageRow = ILSettingRow(
        title: "settings.row.language".localized,
        kind: .chevron
    )

    private lazy var helpRow = ILSettingRow(
        title: "settings.row.help".localized,
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

        let stack = UIStackView(arrangedSubviews: [downloadsRow, languageRow, helpRow])
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

        downloadsRow.onTap = { [weak self] in self?.onDownloadsTap?() }
        languageRow.onTap = { [weak self] in self?.onLanguageTap?() }
        helpRow.onTap = { [weak self] in self?.onHelpTap?() }
    }

    // MARK: - Configure
    func configure(downloadsSummary: String, languageSummary: String) {
        downloadsRow.subtitle = downloadsSummary
        languageRow.subtitle = languageSummary
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
