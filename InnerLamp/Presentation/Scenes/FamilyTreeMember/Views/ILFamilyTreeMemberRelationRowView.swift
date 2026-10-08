//
//  ILFamilyTreeMemberRelationRowView.swift
//  InnerLamp
//

import UIKit

/// One QUAN HỆ row: relation kind, serif name, generation and a chevron. Tapping reports the
/// related member's id.
final class ILFamilyTreeMemberRelationRowView: UIControl {

    private typealias Tree = ILColors.FamilyTree
    private typealias Metrics = ILMetrics.FamilyTree

    private enum Layout {
        static let minHeight: CGFloat = 48
        static let keyWidth: CGFloat = 64
        static let gap: CGFloat = 10
        static let chevronSize = CGSize(width: 14, height: 14)
    }

    // MARK: - Properties
    var onTap: ((String) -> Void)?
    private let memberID: String

    // MARK: - Initializer
    init(relation: ILFamilyTreeRelationModel) {
        memberID = relation.memberID
        super.init(frame: .zero)
        accessibilityTraits = .button
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        let kind = UILabel()
        kind.font = ILTypography.subhead
        kind.textColor = Tree.inkTertiary
        kind.text = relation.kind
        kind.widthAnchor.constraint(equalToConstant: Layout.keyWidth).isActive = true

        let name = UILabel()
        name.font = ILTypography.treeRelationName
        name.textColor = Tree.heading
        name.text = relation.name

        let generation = UILabel()
        generation.font = ILTypography.label
        generation.textColor = Tree.inkMuted
        generation.text = relation.generation
        generation.setContentHuggingPriority(.required, for: .horizontal)

        let chevron = ChevronView()
        chevron.widthAnchor.constraint(equalToConstant: Layout.chevronSize.width).isActive = true
        chevron.heightAnchor.constraint(equalToConstant: Layout.chevronSize.height).isActive = true

        let stack = UIStackView(arrangedSubviews: [kind, name, generation, chevron])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = Layout.gap
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        let bottomLine = UIView()
        bottomLine.backgroundColor = Tree.divider
        bottomLine.isUserInteractionEnabled = false
        bottomLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomLine)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: Layout.minHeight),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            bottomLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomLine.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomLine.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.6 : 1 }
    }

    @objc private func handleTap() { onTap?(memberID) }

    // MARK: - Chevron
    /// Right-pointing chevron, drawn (no asset exists for it).
    private final class ChevronView: UIView {
        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear
            isOpaque = false
            isUserInteractionEnabled = false
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ChevronView, _) in
                view.setNeedsDisplay()
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func draw(_ rect: CGRect) {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: bounds.width * 0.375, y: bounds.height * 0.21))
            path.addLine(to: CGPoint(x: bounds.width * 0.67, y: bounds.height * 0.5))
            path.addLine(to: CGPoint(x: bounds.width * 0.375, y: bounds.height * 0.79))
            path.lineWidth = Metrics.sheetChevronStroke
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            Tree.inkMuted.setStroke()
            path.stroke()
        }
    }
}
