//
//  ILFamilyTreeChronicleTimelineView.swift
//  InnerLamp
//

import UIKit

/// "MỐC LỊCH SỬ" in view mode: year (serif) | gold dot with a line down to the next row | text.
final class ILFamilyTreeChronicleTimelineView: UIView {

    private typealias Tree = ILColors.FamilyTree

    private enum Layout {
        static let yearWidth: CGFloat = 46
        static let railWidth: CGFloat = 12
        static let dotSize: CGFloat = 9
        static let dotTop: CGFloat = 5
        static let lineWidth: CGFloat = 1.5
        static let lineTop: CGFloat = 3
        static let columnGap: CGFloat = 12
        static let rowBottom: CGFloat = 16
    }

    private lazy var stack: UIStackView = {
        let v = UIStackView()
        v.axis = .vertical
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(rows: [ILFamilyTreeChronicleTimelineRow]) {
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        rows.forEach { stack.addArrangedSubview(makeRow($0)) }
    }

    private func makeRow(_ row: ILFamilyTreeChronicleTimelineRow) -> UIView {
        let yearLabel = UILabel()
        yearLabel.text = row.year
        yearLabel.font = ILTypography.treeMemorialTitle
        yearLabel.textColor = Tree.selected
        yearLabel.textAlignment = .right
        yearLabel.setContentHuggingPriority(.required, for: .vertical)

        let dot = UIView()
        dot.backgroundColor = Tree.gold
        dot.layer.cornerRadius = Layout.dotSize / 2
        let line = UIView()
        line.backgroundColor = Tree.border
        line.isHidden = !row.hasNext
        let rail = UIView()
        [dot, line].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            rail.addSubview($0)
        }
        NSLayoutConstraint.activate([
            dot.topAnchor.constraint(equalTo: rail.topAnchor, constant: Layout.dotTop),
            dot.centerXAnchor.constraint(equalTo: rail.centerXAnchor),
            dot.widthAnchor.constraint(equalToConstant: Layout.dotSize),
            dot.heightAnchor.constraint(equalToConstant: Layout.dotSize),
            line.topAnchor.constraint(equalTo: dot.bottomAnchor, constant: Layout.lineTop),
            line.bottomAnchor.constraint(equalTo: rail.bottomAnchor),
            line.centerXAnchor.constraint(equalTo: rail.centerXAnchor),
            line.widthAnchor.constraint(equalToConstant: Layout.lineWidth),
            rail.widthAnchor.constraint(equalToConstant: Layout.railWidth)
        ])

        let textLabel = UILabel()
        textLabel.text = row.text
        textLabel.font = ILTypography.bodySmall
        textLabel.textColor = Tree.ink
        textLabel.numberOfLines = 0

        let textWrap = UIView()
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textWrap.addSubview(textLabel)
        NSLayoutConstraint.activate([
            textLabel.topAnchor.constraint(equalTo: textWrap.topAnchor),
            textLabel.leadingAnchor.constraint(equalTo: textWrap.leadingAnchor),
            textLabel.trailingAnchor.constraint(equalTo: textWrap.trailingAnchor),
            textLabel.bottomAnchor.constraint(equalTo: textWrap.bottomAnchor, constant: -Layout.rowBottom)
        ])

        let yearWrap = UIView()
        yearLabel.translatesAutoresizingMaskIntoConstraints = false
        yearWrap.addSubview(yearLabel)
        NSLayoutConstraint.activate([
            yearLabel.topAnchor.constraint(equalTo: yearWrap.topAnchor),
            yearLabel.leadingAnchor.constraint(equalTo: yearWrap.leadingAnchor),
            yearLabel.trailingAnchor.constraint(equalTo: yearWrap.trailingAnchor),
            yearLabel.bottomAnchor.constraint(lessThanOrEqualTo: yearWrap.bottomAnchor),
            yearWrap.widthAnchor.constraint(equalToConstant: Layout.yearWidth)
        ])

        let container = UIStackView(arrangedSubviews: [yearWrap, rail, textWrap])
        container.axis = .horizontal
        container.alignment = .fill
        container.spacing = Layout.columnGap
        return container
    }
}
