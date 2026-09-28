//
//  ILLunarDayDetailGoodHoursView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 27/9/26.
//

import UIKit

/// Lưới 3 cột × 2 hàng của 6 giờ hoàng đạo — mỗi ô: con giáp (emoji), tên chi và khung giờ (khớp
/// `lnHours` trong design handoff).
final class ILLunarDayDetailGoodHoursView: UIView {

    private static let columns = 3

    // MARK: - Properties
    var hours: [ILLunarDayDetailHourModel] = [] {
        didSet { rebuild() }
    }

    // MARK: - UI Elements
    private let rowsStack = UIStackView()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        rowsStack.axis = .vertical
        rowsStack.spacing = 8
        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rowsStack)

        NSLayoutConstraint.activate([
            rowsStack.topAnchor.constraint(equalTo: topAnchor),
            rowsStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            rowsStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            rowsStack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILLunarDayDetailGoodHoursView, _) in
            view.applyColorAppearanceChange()
        }
    }

    // MARK: - Rebuild
    private func rebuild() {
        rowsStack.arrangedSubviews.forEach {
            rowsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        for start in stride(from: 0, to: hours.count, by: Self.columns) {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 8

            for hour in hours[start..<min(start + Self.columns, hours.count)] {
                rowStack.addArrangedSubview(makeTile(hour))
            }

            // Đệm ô trống để hàng cuối luôn thẳng cột (design luôn đủ 6 ô nên thường không cần).
            while rowStack.arrangedSubviews.count < Self.columns {
                rowStack.addArrangedSubview(UIView())
            }

            rowsStack.addArrangedSubview(rowStack)
        }
    }

    private func makeTile(_ hour: ILLunarDayDetailHourModel) -> UIView {
        let tile = UIView()
        tile.backgroundColor = ILColors.surface
        tile.layer.cornerRadius = ILMetrics.radiusField
        tile.layer.borderWidth = 1
        tile.layer.borderColor = ILColors.border.cgColor
        tile.translatesAutoresizingMaskIntoConstraints = false

        let iconLabel = UILabel()
        iconLabel.font = ILTypography.statValue
        iconLabel.text = hour.icon
        iconLabel.textAlignment = .center

        let nameLabel = UILabel()
        nameLabel.font = ILTypography.dateTileDay
        nameLabel.textColor = ILColors.ink
        nameLabel.text = hour.name
        nameLabel.textAlignment = .center

        let rangeLabel = UILabel()
        rangeLabel.font = ILTypography.label
        rangeLabel.textColor = ILColors.inkTertiary
        rangeLabel.text = hour.range
        rangeLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [iconLabel, nameLabel, rangeLabel])
        stack.axis = .vertical
        stack.spacing = 3
        stack.alignment = .center
        stack.setCustomSpacing(8, after: iconLabel)
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        tile.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: tile.topAnchor, constant: 14),
            stack.bottomAnchor.constraint(equalTo: tile.bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: tile.leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: tile.trailingAnchor, constant: -10)
        ])

        return tile
    }

    private func applyColorAppearanceChange() {
        for row in rowsStack.arrangedSubviews {
            guard let rowStack = row as? UIStackView else { continue }
            for tile in rowStack.arrangedSubviews {
                tile.layer.borderColor = ILColors.border.cgColor
            }
        }
    }
}
