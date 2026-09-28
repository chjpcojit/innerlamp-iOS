//
//  ILToggleCardRow.swift
//  InnerLamp
//
//  Created by ChjpCoj on 12/9/26.
//

import UIKit

/// Card hàng: icon glyph tròn + tiêu đề/phụ đề + `UISwitch`, cả card bấm được để toggle —
/// dùng cho mọi danh sách "bật/tắt 1 lựa chọn" (nhắc nhở, cài đặt, ...). Dữ liệu hoàn toàn
/// động qua init, không phụ thuộc nội dung màn cụ thể nào.
public final class ILToggleCardRow: UIControl {

    // MARK: - Properties
    public var title: String = "" {
        didSet { titleLabel.text = title }
    }

    public var subtitle: String = "" {
        didSet { subtitleLabel.text = subtitle }
    }

    public var isOn: Bool = false {
        didSet {
            switchControl.isOn = isOn
            updateAppearance()
        }
    }

    public var onToggle: ((Bool) -> Void)?

    // MARK: - UI Elements
    private let iconContainer = UIView()
    private let bellGlyph = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let switchControl = UISwitch()

    // MARK: - Initializer
    public init(title: String, subtitle: String = "", isOn: Bool = false) {
        self.title = title
        self.subtitle = subtitle
        self.isOn = isOn
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        layer.cornerRadius = ILMetrics.radiusCardSmall
        layer.borderWidth = 1
        backgroundColor = ILColors.surface

        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.layer.cornerRadius = 17.0
        iconContainer.isUserInteractionEnabled = false

        bellGlyph.translatesAutoresizingMaskIntoConstraints = false
        bellGlyph.layer.cornerRadius = ILMetrics.radiusGlyph
        bellGlyph.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        iconContainer.addSubview(bellGlyph)

        NSLayoutConstraint.activate([
            iconContainer.widthAnchor.constraint(equalToConstant: 34),
            iconContainer.heightAnchor.constraint(equalToConstant: 34),
            bellGlyph.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            bellGlyph.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            bellGlyph.widthAnchor.constraint(equalToConstant: 10),
            bellGlyph.heightAnchor.constraint(equalToConstant: 10)
        ])

        titleLabel.font = ILTypography.beVietnamPro(size: 14.5, weight: .medium)
        titleLabel.textColor = ILColors.ink
        titleLabel.text = title

        subtitleLabel.font = ILTypography.subhead
        subtitleLabel.textColor = ILColors.inkSubtle
        subtitleLabel.text = subtitle

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading
        textStack.isUserInteractionEnabled = false

        switchControl.onTintColor = ILColors.gold
        switchControl.isOn = isOn
        switchControl.isUserInteractionEnabled = false

        let contentStack = UIStackView(arrangedSubviews: [iconContainer, textStack, switchControl])
        contentStack.axis = .horizontal
        contentStack.spacing = 14
        contentStack.alignment = .center
        contentStack.isUserInteractionEnabled = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(contentStack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 68),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
        ])

        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)

        updateAppearance()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILToggleCardRow, _) in
            view.applyColorAppearanceChange()
        }
    }

    private func updateAppearance() {
        // Token động (ink/gold) tự đảo theo trait thay vì set cứng hex light-only.
        if isOn {
            layer.borderColor = ILColors.goldBorder.cgColor
            iconContainer.backgroundColor = ILColors.gold.withAlphaComponent(0.18)
            bellGlyph.backgroundColor = ILColors.gold
        } else {
            layer.borderColor = ILColors.ink.withAlphaComponent(0.10).cgColor
            iconContainer.backgroundColor = ILColors.ink.withAlphaComponent(0.06)
            bellGlyph.backgroundColor = ILColors.ink.withAlphaComponent(0.35)
        }
    }

    // `layer.borderColor` là CGColor tĩnh, không tự đảo theo trait — refresh thủ công
    // khi hệ thống đổi light/dark (ink giờ có biến thể dark).
    private func applyColorAppearanceChange() {
        updateAppearance()
    }

    @objc private func handleTapAction() {
        isOn.toggle()
        switchControl.setOn(isOn, animated: true)
        onToggle?(isOn)
    }
}
