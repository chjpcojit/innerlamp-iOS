//
//  ILFamilyTreeChroniclePlaqueView.swift
//  InnerLamp
//

import UIKit

/// "GIA HUẤN" decoration (view mode): the hoành phi — Han characters on a dark lacquered plaque
/// with a gold ring and the reading underneath — and the two câu đối cards side by side.
final class ILFamilyTreeChroniclePlaqueView: UIView {

    private typealias Tree = ILColors.FamilyTree

    private enum Layout {
        static let plaquePadding = UIEdgeInsets(top: 16, left: 14, bottom: 16, right: 14)
        static let plaqueRadius: CGFloat = 4
        static let ringInset: CGFloat = 3
        static let ringWidth: CGFloat = 1
        static let meaningGap: CGFloat = 4
        static let coupletGap: CGFloat = 8
        static let coupletPadding: CGFloat = 12
        static let coupletRadius: CGFloat = 4
        static let kern: CGFloat = 0.06
    }

    // MARK: - UI Elements
    private lazy var plaqueView = PlaqueBox()
    private lazy var hanLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.treeSheetName
        v.textColor = Tree.founderGold
        v.textAlignment = .center
        v.numberOfLines = 0
        return v
    }()
    private lazy var meaningLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.subheadMedium
        v.textColor = Tree.cream.withAlphaComponent(0.8)
        v.textAlignment = .center
        v.numberOfLines = 0
        return v
    }()
    private lazy var coupletRow: UIStackView = {
        let v = UIStackView()
        v.axis = .horizontal
        v.distribution = .fillEqually
        v.alignment = .fill
        v.spacing = Layout.coupletGap
        return v
    }()
    private lazy var stack: UIStackView = {
        let v = UIStackView()
        v.axis = .vertical
        v.spacing = Layout.coupletGap
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        let plaqueStack = UIStackView(arrangedSubviews: [hanLabel, meaningLabel])
        plaqueStack.axis = .vertical
        plaqueStack.spacing = Layout.meaningGap
        plaqueStack.translatesAutoresizingMaskIntoConstraints = false
        plaqueView.addSubview(plaqueStack)
        NSLayoutConstraint.activate([
            plaqueStack.topAnchor.constraint(equalTo: plaqueView.topAnchor, constant: Layout.plaquePadding.top),
            plaqueStack.bottomAnchor.constraint(equalTo: plaqueView.bottomAnchor, constant: -Layout.plaquePadding.bottom),
            plaqueStack.leadingAnchor.constraint(equalTo: plaqueView.leadingAnchor, constant: Layout.plaquePadding.left),
            plaqueStack.trailingAnchor.constraint(equalTo: plaqueView.trailingAnchor, constant: -Layout.plaquePadding.right)
        ])

        [plaqueView, coupletRow].forEach { stack.addArrangedSubview($0) }
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
    func configure(han: String, meaning: String, couplets: [String]) {
        plaqueView.isHidden = han.isEmpty
        hanLabel.attributedText = NSAttributedString(string: han, attributes: [
            .font: ILTypography.treeSheetName, .foregroundColor: Tree.founderGold, .kern: Layout.kern * 22
        ])
        meaningLabel.text = meaning
        meaningLabel.isHidden = meaning.isEmpty

        coupletRow.arrangedSubviews.forEach {
            coupletRow.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        couplets.forEach { coupletRow.addArrangedSubview(makeCouplet($0)) }
        coupletRow.isHidden = couplets.isEmpty
    }

    private func makeCouplet(_ text: String) -> UIView {
        let card = UIView()
        card.backgroundColor = Tree.memorialGlyphTint
        card.layer.cornerRadius = Layout.coupletRadius
        card.layer.borderWidth = 1
        card.layer.borderColor = Tree.memorialGlyphRing.cgColor
        let label = UILabel()
        label.text = text
        label.font = ILTypography.treeNote
        label.textColor = Tree.seal
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: card.topAnchor, constant: Layout.coupletPadding),
            label.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -Layout.coupletPadding),
            label.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: Layout.coupletPadding),
            label.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -Layout.coupletPadding)
        ])
        return card
    }

    // MARK: - Plaque box
    /// Dark plaque with a thin gold ring inside the edge.
    private final class PlaqueBox: UIView {
        private let ringLayer = CAShapeLayer()

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = Tree.bark
            layer.cornerRadius = Layout.plaqueRadius
            ringLayer.fillColor = nil
            ringLayer.strokeColor = Tree.gold.cgColor
            ringLayer.lineWidth = Layout.ringWidth
            layer.addSublayer(ringLayer)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            ringLayer.path = UIBezierPath(
                roundedRect: bounds.insetBy(dx: Layout.ringInset, dy: Layout.ringInset), cornerRadius: Layout.plaqueRadius
            ).cgPath
        }
    }
}
