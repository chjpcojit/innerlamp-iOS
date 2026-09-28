//
//  ILSettingsDisplayCardView.swift
//  InnerLamp
//

import UIKit

/// Nhóm "Hiển thị & ngôn ngữ" màn Cài đặt: hàng chỉnh cỡ chữ kinh văn (thanh trượt), Song ngữ
/// Việt – Anh (switch) và Chế độ tối (value). Composition riêng của màn Cài đặt.
final class ILSettingsDisplayCardView: UIView {

    // MARK: - Properties
    var onFontScaleChanged: ((Double) -> Void)?
    var onBilingualToggle: ((Bool) -> Void)?
    var onDarkModeTap: (() -> Void)?

    // MARK: - UI Elements (font-size slider row)
    private lazy var fontSizeTitleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.body
        label.textColor = ILColors.ink
        label.text = "settings.row.fontSize".localized
        return label
    }()

    private lazy var smallALabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.scriptureBodyTiny
        label.textColor = ILColors.inkTertiary
        label.text = "A"
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()

    private lazy var largeALabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.scriptureBodyLarge
        label.textColor = ILColors.ink
        label.text = "A"
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()

    private lazy var fontScaleSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.minimumTrackTintColor = ILColors.gold
        slider.maximumTrackTintColor = ILColors.tint2
        slider.thumbTintColor = ILColors.surface
        slider.addTarget(self, action: #selector(handleFontScaleChanged), for: .valueChanged)
        return slider
    }()

    private lazy var fontSizeRow: UIStackView = {
        let sliderRow = UIStackView(arrangedSubviews: [smallALabel, fontScaleSlider, largeALabel])
        sliderRow.axis = .horizontal
        sliderRow.alignment = .center
        sliderRow.spacing = ILMetrics.spaceMedium - 2

        let stack = UIStackView(arrangedSubviews: [fontSizeTitleLabel, sliderRow])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = ILMetrics.spaceMedium - 2
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 15, left: ILMetrics.spaceStandard, bottom: 15, right: ILMetrics.spaceStandard)
        return stack
    }()

    // MARK: - Rows
    private lazy var bilingualRow = ILSettingRow(
        title: "settings.row.bilingual".localized,
        kind: .switch
    )

    private lazy var darkModeRow = ILSettingRow(
        title: "settings.row.darkMode".localized,
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

        let divider = UIView()
        divider.backgroundColor = ILColors.border
        divider.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [fontSizeRow, divider, bilingualRow, darkModeRow])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            divider.heightAnchor.constraint(equalToConstant: 1),

            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        bilingualRow.onSwitchToggled = { [weak self] value in self?.onBilingualToggle?(value) }
        darkModeRow.onTap = { [weak self] in self?.onDarkModeTap?() }
    }

    // MARK: - Configure
    func configure(fontScale: Double, bilingualEnabled: Bool, themeTitle: String) {
        fontScaleSlider.value = Float(fontScale)
        bilingualRow.isOn = bilingualEnabled
        darkModeRow.valueText = themeTitle
    }

    private func applyDynamicColors() {
        layer.borderColor = ILColors.border.cgColor
    }

    private func registerForAppearanceChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.applyDynamicColors()
        }
    }

    @objc private func handleFontScaleChanged() {
        onFontScaleChanged?(Double(fontScaleSlider.value))
    }
}
