//
//  ILTabHeaderView.swift
//  InnerLamp
//

import UIKit

/// Dải tiêu đề dán đầu của màn gốc tab (Trang chủ / Thư viện / Đạo tràng / Tôi): tiêu đề serif
/// bên trái, link hành động tùy chọn bên phải (cùng baseline), hairline ở đáy. Nền phủ kín tới
/// mép trên màn hình — view này cần được ghim `topAnchor` vào `view.topAnchor` của màn để phần
/// status bar nằm trong dải; nội dung tự chừa safe area.
public final class ILTabHeaderView: UIView {

    // MARK: - Properties
    public var title: String = "" {
        didSet { titleLabel.text = title }
    }

    public var trailingText: String? {
        didSet {
            trailingButton.setTitle(trailingText, for: .normal)
            trailingButton.isHidden = trailingText == nil
        }
    }

    public var onTrailingTap: (() -> Void)?

    // MARK: - UI Elements
    private let titleLabel = UILabel()
    private let trailingButton = UIButton(type: .system)
    private let divider = UIView()

    // MARK: - Initializer
    public init(title: String, trailingText: String? = nil) {
        self.title = title
        self.trailingText = trailingText
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.canvas

        titleLabel.font = ILTypography.displayMedium
        titleLabel.textColor = ILColors.ink
        titleLabel.text = title
        titleLabel.accessibilityTraits = .header
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        trailingButton.titleLabel?.font = ILTypography.note
        trailingButton.setTitleColor(ILColors.goldDeep, for: .normal)
        trailingButton.setTitle(trailingText, for: .normal)
        trailingButton.isHidden = trailingText == nil
        trailingButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        trailingButton.translatesAutoresizingMaskIntoConstraints = false
        trailingButton.addTarget(self, action: #selector(handleTrailingTap), for: .touchUpInside)

        divider.backgroundColor = ILColors.border
        divider.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleLabel)
        addSubview(trailingButton)
        addSubview(divider)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceMedium),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.screenHorizontal),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -(ILMetrics.spaceMedium - 2)),

            trailingButton.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: ILMetrics.spaceSmall),
            trailingButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.screenHorizontal),
            trailingButton.lastBaselineAnchor.constraint(equalTo: titleLabel.lastBaselineAnchor),

            divider.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor),
            divider.bottomAnchor.constraint(equalTo: bottomAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    @objc private func handleTrailingTap() {
        onTrailingTap?()
    }
}
