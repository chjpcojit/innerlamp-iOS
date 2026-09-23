//
//  ILStatSummaryCardView.swift
//  InnerLamp
//

import UIKit

/// Thẻ tổng hợp nhiều ô số liệu nằm ngang, ngăn cách bằng đường kẻ dọc — mỗi ô là 1 số lớn + chú
/// thích nhỏ (vd. "168 / giờ tu tập"). Chỉ nhận chuỗi nên dùng chung được cho mọi màn cần dải
/// thống kê.
public final class ILStatSummaryCardView: UIView {

    public struct Item: Equatable {
        public let value: String
        public let caption: String

        public init(value: String, caption: String) {
            self.value = value
            self.caption = caption
        }
    }

    // MARK: - Constants
    private enum Layout {
        static let verticalPadding: CGFloat = 18
        static let horizontalPadding: CGFloat = 6
        static let dividerWidth: CGFloat = 1
    }

    // MARK: - UI Elements
    private lazy var contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()

    // MARK: - Initializer
    public init() {
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

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: Layout.verticalPadding),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.verticalPadding),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalPadding),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalPadding)
        ])
    }

    // MARK: - Configure
    public func configure(items: [Item]) {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        var firstCell: UIView?
        for (index, item) in items.enumerated() {
            if index > 0 { contentStack.addArrangedSubview(makeDivider()) }
            let cell = makeCell(for: item)
            contentStack.addArrangedSubview(cell)
            // Các ô chia đều chiều ngang, không phụ thuộc độ dài chữ.
            if let firstCell {
                cell.widthAnchor.constraint(equalTo: firstCell.widthAnchor).isActive = true
            } else {
                firstCell = cell
            }
        }
    }

    private func makeCell(for item: Item) -> UIView {
        let valueLabel = UILabel()
        valueLabel.font = ILTypography.statValue
        valueLabel.textColor = ILColors.ink
        valueLabel.textAlignment = .center
        valueLabel.text = item.value

        let captionLabel = UILabel()
        captionLabel.font = ILTypography.label
        captionLabel.textColor = ILColors.inkTertiary
        captionLabel.textAlignment = .center
        captionLabel.numberOfLines = 0
        captionLabel.text = item.caption

        let stack = UIStackView(arrangedSubviews: [valueLabel, captionLabel])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 3
        return stack
    }

    private func makeDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = ILColors.border
        divider.widthAnchor.constraint(equalToConstant: Layout.dividerWidth).isActive = true
        return divider
    }

    // `layer.borderColor` là CGColor tĩnh, không tự đảo theo trait — refresh thủ công khi đổi
    // light/dark.
    private func registerForAppearanceChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.layer.borderColor = ILColors.border.cgColor
        }
    }
}
