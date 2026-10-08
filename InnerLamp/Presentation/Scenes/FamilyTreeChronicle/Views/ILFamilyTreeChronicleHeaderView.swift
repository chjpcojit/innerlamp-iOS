//
//  ILFamilyTreeChronicleHeaderView.swift
//  InnerLamp
//

import UIKit

/// Centered masthead of the chronicle: the red 譜 seal, the clan name, the hometown and the
/// "5 đời · 24 người · từ năm 1812" line.
final class ILFamilyTreeChronicleHeaderView: UIView {

    private typealias Tree = ILColors.FamilyTree

    private enum Layout {
        static let sealSize: CGFloat = 52
        static let sealRadius: CGFloat = 6
        static let sealRingInset: CGFloat = 2
        static let sealRotation: CGFloat = -4
        static let sealGap: CGFloat = 14
        static let homeGap: CGFloat = 4
        static let metaGap: CGFloat = 6
    }

    // MARK: - UI Elements
    private lazy var sealView: ILFamilyTreeSealView = {
        let seal = ILFamilyTreeSealView(
            glyph: "familyTreeChronicle.seal".localized, font: ILTypography.treeHeaderTitle, size: Layout.sealSize,
            cornerRadius: Layout.sealRadius, ringInset: Layout.sealRingInset, rotation: Layout.sealRotation
        )
        seal.pinSize()
        return seal
    }()

    private lazy var titleLabel = makeLabel(font: ILTypography.treeEmptyTitle, color: Tree.heading)
    private lazy var homeLabel = makeLabel(font: ILTypography.bodySmall, color: Tree.inkSecondary)
    private lazy var metaLabel = makeLabel(font: ILTypography.subheadMedium, color: Tree.selected)

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        let stack = UIStackView(arrangedSubviews: [sealView, titleLabel, homeLabel, metaLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.setCustomSpacing(Layout.sealGap, after: sealView)
        stack.setCustomSpacing(Layout.homeGap, after: titleLabel)
        stack.setCustomSpacing(Layout.metaGap, after: homeLabel)
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
    /// `showsHome` is `false` while editing, where the hometown has its own input card.
    func configure(title: String, home: String, meta: String, showsHome: Bool) {
        titleLabel.text = title
        homeLabel.text = home
        homeLabel.isHidden = !showsHome || home.isEmpty
        metaLabel.text = meta
    }

    private func makeLabel(font: UIFont, color: UIColor) -> UILabel {
        let label = UILabel()
        label.font = font
        label.textColor = color
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }
}
