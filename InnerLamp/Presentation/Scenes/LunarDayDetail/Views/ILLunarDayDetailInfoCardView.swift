//
//  ILLunarDayDetailInfoCardView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 27/9/26.
//

import UIKit

/// Bảng "Ngày · Tháng · Năm · Dương lịch" — thẻ nổi bật nền gradient `--il-feat-*` (đổi theo
/// light/dark), mỗi hàng là cặp nhãn (trái) + giá trị Can Chi/ngày (phải), không có đường kẻ
/// giữa các hàng (khớp `lnInfo`/`r.bd = transparent` trong design handoff).
final class ILLunarDayDetailInfoCardView: UIView {

    // MARK: - Properties
    var rows: [ILLunarDayDetailInfoRowModel] = [] {
        didSet { rebuild() }
    }

    // MARK: - UI Elements
    private let gradientLayer = CAGradientLayer()
    private lazy var rowsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = ILMetrics.radiusCardRegular
        layer.borderWidth = 1
        clipsToBounds = true

        gradientLayer.startPoint = CGPoint(x: 0.1, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.9, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)

        addSubview(rowsStack)

        NSLayoutConstraint.activate([
            rowsStack.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            rowsStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            rowsStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            rowsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18)
        ])

        updateAppearance()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILLunarDayDetailInfoCardView, _) in
            view.applyColorAppearanceChange()
        }
    }

    private func updateAppearance() {
        gradientLayer.colors = [ILColors.featBackgroundStart.cgColor, ILColors.featBackgroundEnd.cgColor]
        layer.borderColor = ILColors.featBorder.cgColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    private func applyColorAppearanceChange() {
        updateAppearance()
    }

    // MARK: - Rebuild
    private func rebuild() {
        rowsStack.arrangedSubviews.forEach {
            rowsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for row in rows {
            rowsStack.addArrangedSubview(makeRow(row))
        }
    }

    private func makeRow(_ row: ILLunarDayDetailInfoRowModel) -> UIView {
        let keyLabel = UILabel()
        keyLabel.font = ILTypography.bodySmall
        keyLabel.textColor = ILColors.templeHeaderSub
        keyLabel.text = row.key
        keyLabel.setContentHuggingPriority(.required, for: .horizontal)

        let valueLabel = UILabel()
        valueLabel.font = ILTypography.articleBody
        valueLabel.textColor = ILColors.templeHeaderInk
        valueLabel.text = row.value
        valueLabel.textAlignment = .right
        valueLabel.numberOfLines = 1

        let rowStack = UIStackView(arrangedSubviews: [keyLabel, valueLabel])
        rowStack.axis = .horizontal
        rowStack.distribution = .fill
        rowStack.alignment = .center

        // Padding dọc 14pt cho mỗi hàng (khớp `padding:14px 0` trong design handoff).
        rowStack.isLayoutMarginsRelativeArrangement = true
        rowStack.layoutMargins = UIEdgeInsets(top: 14, left: 0, bottom: 14, right: 0)
        return rowStack
    }
}
