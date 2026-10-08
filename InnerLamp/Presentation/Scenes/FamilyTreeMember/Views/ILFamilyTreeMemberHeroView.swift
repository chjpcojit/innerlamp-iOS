//
//  ILFamilyTreeMemberHeroView.swift
//  InnerLamp
//

import UIKit

/// Top block of the profile in view mode: the hexagon medallion (with the clan-head seal), the
/// serif name, the meta line and the status / role / "Với bạn" chips.
final class ILFamilyTreeMemberHeroView: UIView {

    private typealias Tree = ILColors.FamilyTree
    private typealias Metrics = ILMetrics.FamilyTree

    private enum Layout {
        static let medallionWidth: CGFloat = 76
        static let topPadding: CGFloat = 24
        static let nameTopGap: CGFloat = 14
        static let metaTopGap: CGFloat = 4
        static let chipsTopGap: CGFloat = 9
        static let chipsGap: CGFloat = 6
        static let sealOffsetX: CGFloat = 7
        static let sealOffsetY: CGFloat = -2
    }

    // MARK: - UI Elements
    private lazy var medallion = ILFamilyTreeMedallionView()

    private lazy var headSeal: ILFamilyTreeSealView = {
        let seal = ILFamilyTreeSealView(
            glyph: "familyTree.seal.head".localized, font: ILTypography.treeSealSmall,
            size: Metrics.sealSize, cornerRadius: Metrics.sealRadius,
            ringInset: 1.5, rotation: Metrics.sealRotation
        )
        seal.pinSize()
        seal.isHidden = true
        return seal
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.treeEmptyTitle
        label.textColor = Tree.heading
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var metaLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = Tree.inkSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var statusPill = ILFamilyTreeMemberPillView()
    private lazy var rolePill = ILFamilyTreeMemberPillView()
    private lazy var kinshipPill = ILFamilyTreeMemberPillView()

    private lazy var chipsStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [statusPill, rolePill, kinshipPill])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = Layout.chipsGap
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

    private func setupViews() {
        [medallion, headSeal, nameLabel, metaLabel, chipsStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        NSLayoutConstraint.activate([
            medallion.topAnchor.constraint(equalTo: topAnchor, constant: Layout.topPadding),
            medallion.centerXAnchor.constraint(equalTo: centerXAnchor),
            medallion.widthAnchor.constraint(equalToConstant: Layout.medallionWidth),
            medallion.heightAnchor.constraint(equalToConstant: Layout.medallionWidth * Metrics.hexRatio),

            headSeal.trailingAnchor.constraint(equalTo: medallion.trailingAnchor, constant: Layout.sealOffsetX),
            headSeal.topAnchor.constraint(equalTo: medallion.topAnchor, constant: Layout.sealOffsetY),

            nameLabel.topAnchor.constraint(equalTo: medallion.bottomAnchor, constant: Layout.nameTopGap),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            metaLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: Layout.metaTopGap),
            metaLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            metaLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            chipsStack.topAnchor.constraint(equalTo: metaLabel.bottomAnchor, constant: Layout.chipsTopGap),
            chipsStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            chipsStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Configure
    func configure(with state: ILFamilyTreeMemberStateModel) {
        medallion.configure(with: state.look)
        headSeal.isHidden = !state.look.isClanHead
        nameLabel.text = state.name
        metaLabel.text = state.meta
        statusPill.configure(
            text: state.status,
            background: state.look.isLiving ? Tree.livingTint : Tree.deceasedTint,
            foreground: state.look.isLiving ? Tree.forest : Tree.brown
        )
        if let role = state.role {
            rolePill.isHidden = false
            rolePill.configure(text: role, background: state.look.isFounder ? Tree.founderGold : Tree.seal, foreground: Tree.cream)
        } else {
            rolePill.isHidden = true
        }
        if let kinship = state.kinship {
            kinshipPill.isHidden = false
            kinshipPill.configure(text: kinship, background: Tree.meRelation.withAlphaComponent(0.10), foreground: Tree.meRelation)
        } else {
            kinshipPill.isHidden = true
        }
    }
}
