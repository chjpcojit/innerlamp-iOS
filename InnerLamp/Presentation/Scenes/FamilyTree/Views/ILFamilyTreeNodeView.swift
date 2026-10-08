//
//  ILFamilyTreeNodeView.swift
//  InnerLamp
//

import UIKit

/// One person on the canvas: medallion + selection halo + haloed name label + clan-head seal + living dot
/// + optional "DỨT NHÁNH" marker.
/// The view's own frame is the medallion's; the label hangs below it outside the bounds, so the
/// canvas hit-tests through `point(inside:with:)` on the medallion only.
final class ILFamilyTreeNodeView: UIControl {

    // MARK: - Properties
    let memberID: String
    var onTap: (() -> Void)?

    private let medallion = ILFamilyTreeMedallionView()
    private let haloLayer = CAGradientLayer()
    private let livingDot = UIView()
    private let nameLabel = HaloLabel()
    private let metaLabel = HaloLabel()
    private var endedMarker: UIView?
    private var mePill: UILabel?

    // MARK: - Initializer
    init(model: ILFamilyTreeNodeModel) {
        self.memberID = model.id
        super.init(frame: .zero)
        setupViews(model: model)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews(model: ILFamilyTreeNodeModel) {
        typealias Tree = ILColors.FamilyTree
        let metrics = ILMetrics.FamilyTree.self
        let width = model.width
        let height = (width * metrics.hexRatio).rounded()

        frame.size = CGSize(width: width, height: height)
        accessibilityIdentifier = "familyTree.node.\(model.id)"
        accessibilityLabel = model.isMe
            ? "\("familyTree.me.pill".localized), \(model.name), \(model.meta)"
            : "\(model.name), \(model.meta)"
        accessibilityTraits = .button

        layer.shadowColor = Tree.shadow.cgColor
        layer.shadowOpacity = 0.28
        layer.shadowRadius = 5
        layer.shadowOffset = CGSize(width: 0, height: 3)

        haloLayer.type = .radial
        haloLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        haloLayer.endPoint = CGPoint(x: 1, y: 1)
        haloLayer.isHidden = true
        layer.insertSublayer(haloLayer, at: 0)
        let halo = width * metrics.haloRatio
        haloLayer.frame = CGRect(x: (width - halo) / 2, y: (height - halo) / 2, width: halo, height: halo)
        haloLayer.cornerRadius = halo / 2

        medallion.frame = CGRect(x: 0, y: 0, width: width, height: height)
        medallion.configure(with: model.look)
        addSubview(medallion)

        if model.look.isClanHead {
            let seal = ILFamilyTreeSealView(
                glyph: "familyTree.seal.head".localized, font: ILTypography.treeSealSmall,
                size: metrics.sealSize, cornerRadius: metrics.sealRadius,
                ringInset: 1.5, rotation: metrics.sealRotation
            )
            seal.frame = CGRect(x: width - metrics.sealSize + 8, y: -3, width: metrics.sealSize, height: metrics.sealSize)
            addSubview(seal)
        }

        if model.isMe {
            addSubview(makeMePill(width: width))
        }

        if model.look.isLiving {
            livingDot.backgroundColor = Tree.forestLight
            livingDot.layer.cornerRadius = metrics.livingDotSize / 2
            livingDot.layer.borderColor = Tree.cream.cgColor
            livingDot.layer.borderWidth = 2
            livingDot.frame = CGRect(x: (width - metrics.livingDotSize) / 2, y: height - 3,
                                     width: metrics.livingDotSize, height: metrics.livingDotSize)
            livingDot.isUserInteractionEnabled = false
            addSubview(livingDot)
        }

        setupLabels(model: model, width: width, height: height)

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        setSelectedAppearance(false)
        applyShadowPath()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILFamilyTreeNodeView, _) in
            view.applyColorAppearanceChange()
        }
    }

    /// Gold "BẠN" pill centred above the medallion, ringed in paper cream.
    private func makeMePill(width: CGFloat) -> UIView {
        typealias Tree = ILColors.FamilyTree
        let metrics = ILMetrics.FamilyTree.self
        let size = metrics.mePillSize
        let pill = UILabel()
        pill.attributedText = NSAttributedString(
            string: "familyTree.me.pill".localized,
            attributes: [.font: ILTypography.treeMePill, .foregroundColor: Tree.inkOnMe, .kern: 1.14]
        )
        pill.textAlignment = .center
        pill.backgroundColor = Tree.me
        pill.layer.cornerRadius = size.height / 2
        pill.layer.masksToBounds = false
        pill.layer.borderWidth = metrics.mePillRingWidth
        pill.layer.borderColor = Tree.cream.cgColor
        pill.isUserInteractionEnabled = false
        pill.accessibilityIdentifier = "familyTree.mePill"
        pill.frame = CGRect(
            x: (width - size.width) / 2, y: -(size.height + metrics.mePillGap),
            width: size.width, height: size.height
        )
        mePill = pill
        return pill
    }

    /// Name, meta line and optional "DỨT NHÁNH" marker hang below the medallion. The two text
    /// labels draw a stacked cream glow, so they are padded and overlap their neighbours' padding.
    private func setupLabels(model: ILFamilyTreeNodeModel, width: CGFloat, height: CGFloat) {
        typealias Tree = ILColors.FamilyTree
        let metrics = ILMetrics.FamilyTree.self
        let pad = metrics.labelHaloPadding
        let labelWidth = metrics.nodeLabelWidth
        let x = (width - labelWidth) / 2 - pad

        nameLabel.text = model.name
        nameLabel.font = ILTypography.treeNodeName
        nameLabel.textAlignment = .center
        metaLabel.attributedText = NSAttributedString(
            string: model.meta,
            attributes: [.font: ILTypography.treeNodeMeta, .foregroundColor: Tree.inkTertiary, .kern: 0.72]
        )
        metaLabel.textAlignment = .center
        [nameLabel, metaLabel].forEach {
            $0.padding = pad
            $0.haloColor = Tree.labelHalo
            $0.blurs = metrics.labelHaloBlurs
            $0.isUserInteractionEnabled = false
            $0.backgroundColor = .clear
        }

        let nameTop = height + metrics.nodeLabelGap
        let nameHeight = ceil(ILTypography.treeNodeName.lineHeight)
        let metaTop = nameTop + nameHeight + 1
        let metaHeight = ceil(ILTypography.treeNodeMeta.lineHeight)
        nameLabel.frame = CGRect(x: x, y: nameTop - pad, width: labelWidth + pad * 2, height: nameHeight + pad * 2)
        metaLabel.frame = CGRect(x: x, y: metaTop - pad, width: labelWidth + pad * 2, height: metaHeight + pad * 2)
        addSubview(nameLabel)
        addSubview(metaLabel)

        if model.isBranchEnd {
            let marker = makeEndedMarker()
            let size = marker.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            marker.frame = CGRect(
                x: (width - size.width) / 2, y: metaTop + metaHeight + metrics.nodeEndedTopSpacing,
                width: size.width, height: size.height
            )
            addSubview(marker)
            endedMarker = marker
        }
    }

    /// "— DỨT NHÁNH —": brown 10×1.5 rules either side of a small tracked caption.
    private func makeEndedMarker() -> UIView {
        typealias Tree = ILColors.FamilyTree
        let metrics = ILMetrics.FamilyTree.self
        func rule() -> UIView {
            let line = UIView()
            line.backgroundColor = Tree.brown
            line.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                line.widthAnchor.constraint(equalToConstant: metrics.nodeEndedLineSize.width),
                line.heightAnchor.constraint(equalToConstant: metrics.nodeEndedLineSize.height)
            ])
            return line
        }
        let caption = UILabel()
        caption.attributedText = NSAttributedString(
            string: "familyTree.node.ended".localized,
            attributes: [.font: ILTypography.treeBranchEnd, .foregroundColor: Tree.brown, .kern: 1.19]
        )
        let stack = UIStackView(arrangedSubviews: [rule(), caption, rule()])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = metrics.nodeEndedGap
        stack.isUserInteractionEnabled = false
        return stack
    }

    // MARK: - Appearance
    func setSelectedAppearance(_ isSelected: Bool) {
        haloLayer.isHidden = !isSelected
        nameLabel.textColor = isSelected ? ILColors.FamilyTree.selected : ILColors.FamilyTree.heading
        haloLayer.colors = [ILColors.FamilyTree.halo.resolvedColor(with: traitCollection).cgColor,
                            ILColors.FamilyTree.halo.withAlphaComponent(0).resolvedColor(with: traitCollection).cgColor]
    }

    override var isHighlighted: Bool {
        didSet { transform = isHighlighted ? CGAffineTransform(scaleX: 0.94, y: 0.94) : .identity }
    }

    private func applyShadowPath() {
        layer.shadowPath = ILFamilyTreeMedallionView.hexagon(in: medallion.frame).cgPath
    }

    private func applyColorAppearanceChange() {
        layer.shadowColor = ILColors.FamilyTree.shadow.cgColor
        livingDot.layer.borderColor = ILColors.FamilyTree.cream.cgColor
        mePill?.layer.borderColor = ILColors.FamilyTree.cream.cgColor
        setSelectedAppearance(!haloLayer.isHidden)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        medallion.frame.insetBy(dx: -4, dy: -4).contains(point)
    }

    @objc private func handleTap() {
        onTap?()
    }
}

// MARK: - Halo label
private extension ILFamilyTreeNodeView {

    /// Label whose text carries a stacked soft glow in the paper colour (CSS `text-shadow` with
    /// several blur radii), keeping it legible over branches. `padding` leaves room for the glow.
    final class HaloLabel: UILabel {
        var padding: CGFloat = 0
        var haloColor: UIColor = .clear
        var blurs: [CGFloat] = []

        override func drawText(in rect: CGRect) {
            let inner = rect.insetBy(dx: padding, dy: padding)
            guard let context = UIGraphicsGetCurrentContext() else {
                super.drawText(in: inner)
                return
            }
            for blur in blurs {
                context.saveGState()
                context.setShadow(offset: .zero, blur: blur, color: haloColor.cgColor)
                super.drawText(in: inner)
                context.restoreGState()
            }
            super.drawText(in: inner)
        }
    }
}
