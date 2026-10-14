//
//  ILFestivalDetailListCardView.swift
//  InnerLamp
//

import UIKit

/// EN: Numbered list card of the festival detail screen ("what Buddhists usually do"). With no items it
///     shows `emptyText` inside the same card — a section is never hidden. Also used for sections
///     without a data source yet ("sutras to recite", "hosting temples") with empty `items`.
/// VI: Thẻ danh sách đánh số của màn "Chi tiết ngày lễ" (mục "Phật tử thường làm gì"). Không có mục
///     nào thì hiện `emptyText` trong cùng thẻ — mục không bao giờ bị ẩn. Cũng dùng cho các mục
///     chưa có nguồn dữ liệu ("Kinh nên tụng", "Chùa tổ chức") với `items` rỗng.
final class ILFestivalDetailListCardView: UIView {

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let rowVerticalInset: CGFloat = 14
        static let rowSpacing: CGFloat = 14
        static let badgeSize: CGFloat = 24
    }

    // MARK: - UI Elements
    private lazy var stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
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
    func configure(items: [String], emptyText: String) {
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        guard !items.isEmpty else {
            stack.addArrangedSubview(makeEmptyRow(text: emptyText))
            return
        }
        for (index, item) in items.enumerated() {
            if index > 0 { stack.addArrangedSubview(makeSeparator()) }
            stack.addArrangedSubview(makeRow(number: index + 1, text: item))
        }
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardRegular
        layer.borderWidth = ILMetrics.hairline

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalInset),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalInset)
        ])

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILFestivalDetailListCardView, _) in
            view.applyBorderColor()
        }
    }

    // EN: Resolve the static CGColor against the live trait (init-time value resolves as light).
    // VI: Resolve CGColor tĩnh theo trait hiện tại (giá trị lúc init luôn ra màu light).
    private func applyBorderColor() {
        layer.borderColor = ILColors.border.resolvedColor(with: traitCollection).cgColor
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        applyBorderColor()
    }

    // MARK: - Rows
    private func makeRow(number: Int, text: String) -> UIView {
        let badge = UILabel()
        badge.font = ILTypography.chip
        badge.textColor = ILColors.link
        badge.textAlignment = .center
        badge.text = "\(number)"
        badge.layer.cornerRadius = Layout.badgeSize / 2
        badge.layer.borderWidth = ILMetrics.hairline
        badge.layer.borderColor = ILColors.goldBorder.cgColor
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.widthAnchor.constraint(equalToConstant: Layout.badgeSize).isActive = true
        badge.heightAnchor.constraint(equalToConstant: Layout.badgeSize).isActive = true

        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = ILTypography.makeParagraph(
            text: text,
            font: ILTypography.bodyCompact,
            color: ILColors.ink,
            cssLineHeight: 1.5
        )

        let row = UIStackView(arrangedSubviews: [badge, label])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = Layout.rowSpacing
        return inset(row)
    }

    private func makeEmptyRow(text: String) -> UIView {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = ILTypography.bodyCompact
        label.textColor = ILColors.inkSubtle
        label.text = text
        return inset(label)
    }

    private func makeSeparator() -> UIView {
        let line = UIView()
        line.backgroundColor = ILColors.border
        line.translatesAutoresizingMaskIntoConstraints = false
        line.heightAnchor.constraint(equalToConstant: ILMetrics.hairline).isActive = true
        return line
    }

    private func inset(_ content: UIView) -> UIView {
        let container = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: container.topAnchor, constant: Layout.rowVerticalInset),
            content.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -Layout.rowVerticalInset),
            content.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
        return container
    }
}
