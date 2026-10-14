//
//  ILTempleStatusCardView.swift
//  InnerLamp
//

import UIKit

/// Thẻ trạng thái mở cửa ở Trang chùa — khớp `isTemple` trong design handoff: chấm tròn +
/// "Đang mở cửa"/"Đã đóng cửa" + ghi chú giờ, khoảng cách bên phải; dưới là 2 dòng giờ (Ngày
/// thường, Rằm & Mùng Một) với nhãn "Hôm nay" trên dòng đang áp dụng. Riêng cho Trang chùa nên ở
/// `Scenes/Temple` (bố cục cố định của màn này).
final class ILTempleStatusCardView: UIView {

    // MARK: - UI Elements
    private lazy var statusDot: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 4
        return v
    }()
    private lazy var statusLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.bodySmallMedium
        v.setContentHuggingPriority(.required, for: .horizontal)
        return v
    }()
    private lazy var noteLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.bodySmall
        v.textColor = ILColors.inkTertiary
        v.setContentHuggingPriority(.required, for: .horizontal)
        return v
    }()
    private lazy var distanceLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.label
        v.textColor = ILColors.inkTertiary
        v.setContentHuggingPriority(.required, for: .horizontal)
        v.textAlignment = .right
        return v
    }()
    private lazy var statusRow: UIStackView = {
        let v = UIStackView()
        v.axis = .horizontal
        v.spacing = 8
        v.alignment = .center
        return v
    }()

    private lazy var divider: UIView = {
        let v = UIView()
        v.backgroundColor = ILColors.borderSoft
        return v
    }()
    private lazy var hoursStack: UIStackView = {
        let v = UIStackView()
        v.axis = .vertical
        v.spacing = 8
        return v
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration
    func configure(isOpen: Bool, statusText: String, noteText: String, distanceText: String, hourRows: [ILTempleHourRowModel]) {
        statusDot.backgroundColor = isOpen ? ILColors.green : ILColors.inkTertiary
        statusLabel.text = statusText
        statusLabel.textColor = isOpen ? ILColors.greenText : ILColors.inkSecondary
        noteLabel.text = "· \(noteText)"
        noteLabel.isHidden = noteText.isEmpty
        distanceLabel.text = distanceText

        hoursStack.arrangedSubviews.forEach {
            hoursStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        hourRows.forEach { hoursStack.addArrangedSubview(ILTempleHourRow(model: $0)) }
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardLarge
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor

        NSLayoutConstraint.activate([
            statusDot.widthAnchor.constraint(equalToConstant: 8),
            statusDot.heightAnchor.constraint(equalToConstant: 8)
        ])

        statusRow.addArrangedSubview(statusDot)
        statusRow.addArrangedSubview(statusLabel)
        statusRow.addArrangedSubview(noteLabel)
        statusRow.addArrangedSubview(UIView())
        statusRow.addArrangedSubview(distanceLabel)

        let contentStack = UIStackView(arrangedSubviews: [statusRow, divider, hoursStack])
        contentStack.axis = .vertical
        contentStack.setCustomSpacing(14, after: statusRow)
        contentStack.setCustomSpacing(12, after: divider)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            divider.heightAnchor.constraint(equalToConstant: 1),

            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILTempleStatusCardView, _) in
            view.applyColorAppearanceChange()
        }
    }

    private func applyColorAppearanceChange() {
        layer.borderColor = ILColors.border.cgColor
    }
}

/// 1 dòng giờ mở cửa (nhãn + nhãn "Hôm nay" tùy chọn + giờ) trong `ILTempleStatusCardView`.
private final class ILTempleHourRow: UIStackView {

    init(model: ILTempleHourRowModel) {
        super.init(frame: .zero)

        let labelView = UILabel()
        labelView.font = ILTypography.bodySmall
        labelView.textColor = ILColors.inkSecondary
        labelView.text = model.label

        let todayBadge = UILabel()
        todayBadge.font = ILTypography.captionMedium
        todayBadge.textColor = ILColors.link
        todayBadge.backgroundColor = ILColors.gold.withAlphaComponent(0.14)
        todayBadge.layer.cornerRadius = 999 / 2
        todayBadge.clipsToBounds = true
        todayBadge.textAlignment = .center
        todayBadge.text = "  \("temple.hours.today".localized)  "
        todayBadge.isHidden = !model.isToday

        let valueLabel = UILabel()
        valueLabel.font = ILTypography.bodySmallMedium
        valueLabel.textColor = ILColors.ink
        valueLabel.text = model.value
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)

        axis = .horizontal
        spacing = 8
        alignment = .center
        addArrangedSubview(labelView)
        addArrangedSubview(todayBadge)
        addArrangedSubview(UIView())
        addArrangedSubview(valueLabel)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
