//
//  ILFamilyTreeChroniclePeopleView.swift
//  InnerLamp
//

import UIKit

/// "NGƯỜI TIÊU BIỂU": tappable rows (name, two-line note, generation, chevron) separated by hairlines.
final class ILFamilyTreeChroniclePeopleView: UIView {

    private typealias Tree = ILColors.FamilyTree

    private enum Layout {
        static let rowMinHeight: CGFloat = 56
        static let rowPadding: CGFloat = 8
        static let columnGap: CGFloat = 10
        static let noteLines = 2
    }

    // MARK: - Properties
    var onPick: ((String) -> Void)?

    private let stack = UIStackView()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
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

    // MARK: - Configure
    func configure(rows: [ILFamilyTreeChroniclePersonRow]) {
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        rows.forEach { stack.addArrangedSubview(makeRow($0)) }
    }

    private func makeRow(_ row: ILFamilyTreeChroniclePersonRow) -> UIView {
        let control = ILFamilyTreeChronicleTapControl()
        control.accessibilityLabel = row.name
        control.onTap = { [weak self] in self?.onPick?(row.memberID) }

        let nameLabel = UILabel()
        nameLabel.text = row.name
        nameLabel.font = ILTypography.treeRelationName
        nameLabel.textColor = Tree.heading
        let noteLabel = UILabel()
        noteLabel.text = row.subtitle
        noteLabel.font = ILTypography.caption
        noteLabel.textColor = Tree.inkTertiary
        noteLabel.numberOfLines = Layout.noteLines
        noteLabel.isHidden = row.subtitle.isEmpty
        let textStack = UIStackView(arrangedSubviews: [nameLabel, noteLabel])
        textStack.axis = .vertical

        let generationLabel = UILabel()
        generationLabel.text = row.generation
        generationLabel.font = ILTypography.caption
        generationLabel.textColor = Tree.inkMuted
        generationLabel.setContentHuggingPriority(.required, for: .horizontal)
        generationLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let content = UIStackView(arrangedSubviews: [textStack, generationLabel, ILFamilyTreeChronicleChevronView()])
        content.axis = .horizontal
        content.alignment = .center
        content.spacing = Layout.columnGap
        content.isUserInteractionEnabled = false

        let divider = UIView()
        divider.backgroundColor = Tree.divider
        [content, divider].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            control.addSubview($0)
        }
        NSLayoutConstraint.activate([
            control.heightAnchor.constraint(greaterThanOrEqualToConstant: Layout.rowMinHeight),
            content.topAnchor.constraint(equalTo: control.topAnchor, constant: Layout.rowPadding),
            content.bottomAnchor.constraint(equalTo: control.bottomAnchor, constant: -Layout.rowPadding),
            content.leadingAnchor.constraint(equalTo: control.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: control.trailingAnchor),
            divider.leadingAnchor.constraint(equalTo: control.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: control.trailingAnchor),
            divider.bottomAnchor.constraint(equalTo: control.bottomAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1)
        ])
        return control
    }
}
