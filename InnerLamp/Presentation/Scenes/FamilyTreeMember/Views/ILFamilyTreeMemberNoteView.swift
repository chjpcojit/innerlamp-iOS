//
//  ILFamilyTreeMemberNoteView.swift
//  InnerLamp
//

import UIKit

/// TIỂU SỬ block: the biography in a cream card, or — when nothing is written — a dashed box that
/// invites the user to start editing (`onEmptyTap`).
final class ILFamilyTreeMemberNoteView: UIView {

    private typealias Tree = ILColors.FamilyTree

    private enum Layout {
        static let padding: CGFloat = 14
        static let verticalPadding: CGFloat = 12
        static let radius: CGFloat = 6
        static let dash: [NSNumber] = [4, 3]
    }

    // MARK: - Properties
    var onEmptyTap: (() -> Void)?

    private var isEmpty = true
    private let dashedBorder = CAShapeLayer()

    private lazy var label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = Layout.radius
        dashedBorder.fillColor = nil
        dashedBorder.lineWidth = 1
        dashedBorder.lineDashPattern = Layout.dash
        layer.addSublayer(dashedBorder)

        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: Layout.verticalPadding),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.verticalPadding),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.padding),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.padding)
        ])
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILFamilyTreeMemberNoteView, _) in
            view.applyAppearance()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    /// `nil` or empty shows the dashed placeholder.
    func configure(note: String?) {
        let text = note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        isEmpty = text.isEmpty
        if isEmpty {
            label.font = ILTypography.bodySmall
            label.textColor = Tree.inkSecondary
            label.text = "familyTreeMember.note.empty".localized
        } else {
            label.font = ILTypography.treeNote
            label.textColor = Tree.ink
            label.text = text
        }
        accessibilityTraits = isEmpty ? .button : .staticText
        applyAppearance()
    }

    private func applyAppearance() {
        backgroundColor = isEmpty ? .clear : Tree.cardSurface
        layer.borderWidth = isEmpty ? 0 : 1
        layer.borderColor = Tree.cardRing.cgColor
        dashedBorder.isHidden = !isEmpty
        dashedBorder.strokeColor = Tree.brown.withAlphaComponent(0.30).cgColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        dashedBorder.frame = bounds
        dashedBorder.path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), cornerRadius: Layout.radius
        ).cgPath
    }

    @objc private func handleTap() {
        guard isEmpty else { return }
        onEmptyTap?()
    }
}
