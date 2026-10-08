//
//  ILFamilyTreeMemberInfoCardView.swift
//  InnerLamp
//

import UIKit

/// THÔNG TIN card: "key  value" rows inside a cream card. A link row (tablet temple) is underlined
/// and reports taps through `onLinkTap`.
final class ILFamilyTreeMemberInfoCardView: UIView {

    private typealias Tree = ILColors.FamilyTree
    private typealias Metrics = ILMetrics.FamilyTree

    private enum Layout {
        static let padding: CGFloat = 14
        static let rowGap: CGFloat = 10
        static let columnGap: CGFloat = 12
        static let keyWidth: CGFloat = 96
    }

    // MARK: - Properties
    var onLinkTap: (() -> Void)?

    private lazy var rowsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Layout.rowGap
        return stack
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Tree.cardSurface
        layer.cornerRadius = Metrics.sheetCardRadius
        layer.borderWidth = 1
        layer.borderColor = Tree.cardRing.cgColor
        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rowsStack)
        NSLayoutConstraint.activate([
            rowsStack.topAnchor.constraint(equalTo: topAnchor, constant: Layout.padding),
            rowsStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.padding),
            rowsStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.padding),
            rowsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.padding)
        ])
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILFamilyTreeMemberInfoCardView, _) in
            view.layer.borderColor = Tree.cardRing.cgColor
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    func configure(facts: [ILFamilyTreeMemberFactModel]) {
        rowsStack.arrangedSubviews.forEach {
            rowsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        facts.forEach { rowsStack.addArrangedSubview(makeRow($0)) }
    }

    private func makeRow(_ fact: ILFamilyTreeMemberFactModel) -> UIView {
        let keyLabel = UILabel()
        keyLabel.font = ILTypography.bodySmall
        keyLabel.textColor = Tree.inkTertiary
        keyLabel.text = fact.key
        keyLabel.widthAnchor.constraint(equalToConstant: Layout.keyWidth).isActive = true

        let valueLabel = UILabel()
        valueLabel.font = fact.isEmphasized ? ILTypography.bodySmallSemibold : ILTypography.bodySmall
        valueLabel.textColor = fact.isEmphasized ? Tree.meRelation : Tree.ink
        valueLabel.numberOfLines = 0
        valueLabel.text = fact.value

        if fact.isLink {
            valueLabel.attributedText = NSAttributedString(string: fact.value, attributes: [
                .font: ILTypography.bodySmallMedium,
                .foregroundColor: Tree.selected,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .underlineColor: Tree.linkUnderline
            ])
            valueLabel.isUserInteractionEnabled = true
            valueLabel.accessibilityTraits = .link
            valueLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleLinkTap)))
        }

        let row = UIStackView(arrangedSubviews: [keyLabel, valueLabel])
        row.axis = .horizontal
        row.alignment = .firstBaseline
        row.spacing = Layout.columnGap
        return row
    }

    @objc private func handleLinkTap() { onLinkTap?() }
}
