//
//  ILFamilyTreeAddMemberPickerView.swift
//  InnerLamp
//

import UIKit

/// Scrollable list of everyone in the tree; tapping a row picks them as the relative. The selected
/// row is tinted gold.
final class ILFamilyTreeAddMemberPickerView: UIView {

    private typealias Tree = ILColors.FamilyTree

    private enum Layout {
        static let maxHeight: CGFloat = 240
        static let rowHeight: CGFloat = 44
        static let rowPadding: CGFloat = 14
        static let rowGap: CGFloat = 10
    }

    // MARK: - Properties
    var onPick: ((String) -> Void)?

    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private lazy var heightConstraint = heightAnchor.constraint(equalToConstant: Layout.rowHeight)

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Tree.creamLight
        layer.cornerRadius = ILMetrics.radiusInput
        layer.borderWidth = 1
        layer.borderColor = Tree.cardRing.cgColor
        clipsToBounds = true

        stack.axis = .vertical
        [scrollView, stack].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        addSubview(scrollView)
        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            heightConstraint
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    func configure(rows: [ILFamilyTreeAddMemberPersonRow]) {
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        rows.forEach { stack.addArrangedSubview(makeRow($0)) }
        heightConstraint.constant = min(CGFloat(rows.count) * Layout.rowHeight, Layout.maxHeight)
    }

    // MARK: - Factories
    private func makeRow(_ row: ILFamilyTreeAddMemberPersonRow) -> UIView {
        let container = RowControl()
        container.backgroundColor = row.isSelected ? Tree.pickerSelectedRow : .clear
        container.onTap = { [weak self] in self?.onPick?(row.id) }

        let name = UILabel()
        name.text = row.name
        name.font = ILTypography.treeRelationName
        name.textColor = row.isSelected ? Tree.selected : Tree.heading
        let meta = UILabel()
        meta.text = row.meta
        meta.font = ILTypography.caption
        meta.textColor = Tree.inkMuted
        meta.setContentHuggingPriority(.required, for: .horizontal)
        meta.setContentCompressionResistancePriority(.required, for: .horizontal)

        let content = UIStackView(arrangedSubviews: [name, meta])
        content.spacing = Layout.rowGap
        content.isUserInteractionEnabled = false
        content.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(content)

        let divider = UIView()
        divider.backgroundColor = Tree.divider
        divider.isUserInteractionEnabled = false
        divider.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(divider)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: Layout.rowHeight),
            content.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: Layout.rowPadding),
            content.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -Layout.rowPadding),
            content.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            divider.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            divider.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1)
        ])
        return container
    }

    private final class RowControl: UIControl {
        var onTap: (() -> Void)?

        override init(frame: CGRect) {
            super.init(frame: frame)
            addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc private func handleTap() { onTap?() }
    }
}
