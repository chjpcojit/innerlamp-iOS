//
//  ILFamilyTreeChronicleFounderCardView.swift
//  InnerLamp
//

import UIKit

/// "Thủy tổ" card: a gold hexagon, the founder's name and years, and a chevron. Tapping opens the
/// founder in the tree.
final class ILFamilyTreeChronicleFounderCardView: UIView {

    private typealias Tree = ILColors.FamilyTree

    private enum Layout {
        static let hexSize = CGSize(width: 30, height: 33)
        static let insets = UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
        static let gap: CGFloat = 12
        static let textGap: CGFloat = 1
    }

    // MARK: - Properties
    var onTap: (() -> Void)?

    private let tapControl = ILFamilyTreeChronicleTapControl()
    private let hexLayer = CAShapeLayer()
    private let hexView = UIView()
    private let captionLabel = UILabel()
    private let nameLabel = UILabel()
    private let yearsLabel = UILabel()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    func configure(name: String, years: String, isTappable: Bool) {
        nameLabel.text = name
        yearsLabel.text = years
        yearsLabel.isHidden = years.isEmpty
        tapControl.isEnabled = isTappable
        tapControl.accessibilityLabel = name
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = Tree.cardSurface
        layer.cornerRadius = ILMetrics.FamilyTree.sheetCardRadius
        layer.borderWidth = 1
        layer.borderColor = Tree.cardRing.cgColor

        hexLayer.path = ILFamilyTreeMedallionView.hexagon(in: CGRect(origin: .zero, size: Layout.hexSize)).cgPath
        hexLayer.fillColor = Tree.founderGold.cgColor
        hexView.layer.addSublayer(hexLayer)

        captionLabel.text = "familyTree.role.founder".localized
        captionLabel.font = ILTypography.caption
        captionLabel.textColor = Tree.inkTertiary
        nameLabel.font = ILTypography.treeMemorialTitle
        nameLabel.textColor = Tree.heading
        nameLabel.numberOfLines = 0
        yearsLabel.font = ILTypography.caption
        yearsLabel.textColor = Tree.inkSecondary
        yearsLabel.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [captionLabel, nameLabel, yearsLabel])
        textStack.axis = .vertical
        textStack.spacing = Layout.textGap
        let chevron = ILFamilyTreeChronicleChevronView()

        let row = UIStackView(arrangedSubviews: [hexView, textStack, chevron])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = Layout.gap
        row.isUserInteractionEnabled = false

        tapControl.onTap = { [weak self] in self?.onTap?() }
        [tapControl, row].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        hexView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hexView.widthAnchor.constraint(equalToConstant: Layout.hexSize.width),
            hexView.heightAnchor.constraint(equalToConstant: Layout.hexSize.height),
            tapControl.topAnchor.constraint(equalTo: topAnchor),
            tapControl.bottomAnchor.constraint(equalTo: bottomAnchor),
            tapControl.leadingAnchor.constraint(equalTo: leadingAnchor),
            tapControl.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.topAnchor.constraint(equalTo: topAnchor, constant: Layout.insets.top),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.insets.bottom),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.insets.left),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.insets.right)
        ])
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILFamilyTreeChronicleFounderCardView, _) in
            view.layer.borderColor = Tree.cardRing.cgColor
        }
    }
}
