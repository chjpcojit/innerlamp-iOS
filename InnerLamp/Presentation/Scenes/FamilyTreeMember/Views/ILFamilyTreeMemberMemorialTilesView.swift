//
//  ILFamilyTreeMemberMemorialTilesView.swift
//  InnerLamp
//

import UIKit

/// TƯỞNG NIỆM row: three equal tiles — "Nhắc giỗ", "Thắp đèn", "Tụng kinh".
final class ILFamilyTreeMemberMemorialTilesView: UIView {

    private typealias Tree = ILColors.FamilyTree
    private typealias Metrics = ILMetrics.FamilyTree

    private enum Layout {
        static let tileMinHeight: CGFloat = 52
        static let tilePadding: CGFloat = 6
    }

    // MARK: - Properties
    var onRemind: (() -> Void)?
    var onLightLamp: (() -> Void)?
    var onChant: (() -> Void)?

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        let tiles = [
            makeTile(title: "familyTreeMember.memorial.remind".localized, id: "familyTreeMember.remind") { [weak self] in self?.onRemind?() },
            makeTile(title: "familyTree.memorial.offerTitle".localized, id: "familyTreeMember.lightLamp") { [weak self] in self?.onLightLamp?() },
            makeTile(title: "familyTree.memorial.chantTitle".localized, id: "familyTreeMember.chant") { [weak self] in self?.onChant?() }
        ]
        let stack = UIStackView(arrangedSubviews: tiles)
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = ILMetrics.spaceSmall
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

    private func makeTile(title: String, id: String, onTap: @escaping () -> Void) -> UIView {
        let tile = TileControl()
        tile.onTap = onTap
        tile.accessibilityIdentifier = id
        tile.accessibilityLabel = title
        tile.backgroundColor = Tree.cardSurface
        tile.layer.cornerRadius = Metrics.sheetCardRadius
        tile.layer.borderWidth = 1
        tile.layer.borderColor = Tree.cardRing.cgColor

        let label = UILabel()
        label.font = ILTypography.bodySmallMedium
        label.textColor = Tree.ink
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = title
        label.isUserInteractionEnabled = false
        label.translatesAutoresizingMaskIntoConstraints = false
        tile.addSubview(label)
        NSLayoutConstraint.activate([
            tile.heightAnchor.constraint(greaterThanOrEqualToConstant: Layout.tileMinHeight),
            label.leadingAnchor.constraint(equalTo: tile.leadingAnchor, constant: Layout.tilePadding),
            label.trailingAnchor.constraint(equalTo: tile.trailingAnchor, constant: -Layout.tilePadding),
            label.centerYAnchor.constraint(equalTo: tile.centerYAnchor)
        ])
        return tile
    }

    private final class TileControl: UIControl {
        var onTap: (() -> Void)?

        override init(frame: CGRect) {
            super.init(frame: frame)
            addTarget(self, action: #selector(handleTap), for: .touchUpInside)
            accessibilityTraits = .button
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var isHighlighted: Bool {
            didSet { alpha = isHighlighted ? 0.6 : 1 }
        }

        @objc private func handleTap() { onTap?() }
    }
}
