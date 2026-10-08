//
//  ILFamilyTreeCanvasView.swift
//  InnerLamp
//

import UIKit

/// The drawn tree: trunk, bark branches, gold lineage line, spouse links, leaves and one
/// `ILFamilyTreeNodeView` per person. Everything is vector (`CAShapeLayer`) so the enclosing
/// scroll view can zoom it without blurring. Frame = `layout.canvasSize`.
final class ILFamilyTreeCanvasView: UIView {

    private typealias Tree = ILColors.FamilyTree
    private typealias Metrics = ILMetrics.FamilyTree

    // MARK: - Properties
    var onMemberTapped: ((String) -> Void)?

    private var nodeViews: [String: ILFamilyTreeNodeView] = [:]
    private var lineageLayers: [String: CAShapeLayer] = [:]
    private var drawnLayers: [CALayer] = []
    private var layout = ILFamilyTreeLayout.empty

    private let canopyGlow = CAGradientLayer()
    private let groundGlow = CAGradientLayer()

    private lazy var captionLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.heroSubtitleItalic
        label.textColor = Tree.cream
        label.text = "familyTree.canvas.caption".localized
        label.textAlignment = .center
        label.isUserInteractionEnabled = false
        return label
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        [canopyGlow, groundGlow].forEach {
            $0.type = .radial
            $0.startPoint = CGPoint(x: 0.5, y: 0.5)
            $0.endPoint = CGPoint(x: 1, y: 1)
            layer.addSublayer($0)
        }
        canopyGlow.colors = [Tree.canopyGlow.cgColor, Tree.canopyGlow.withAlphaComponent(0).cgColor]
        groundGlow.colors = [Tree.groundShadow.cgColor, Tree.groundShadow.withAlphaComponent(0).cgColor]
        addSubview(captionLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    /// Rebuilds the whole drawing — only when the tree data (layout / nodes) changes.
    func configure(layout: ILFamilyTreeLayout, nodes: [ILFamilyTreeNodeModel]) {
        self.layout = layout
        frame.size = layout.canvasSize
        drawnLayers.forEach { $0.removeFromSuperlayer() }
        drawnLayers = []
        lineageLayers = [:]
        nodeViews.values.forEach { $0.removeFromSuperview() }
        nodeViews = [:]
        guard !nodes.isEmpty else { return }

        let size = layout.canvasSize
        canopyGlow.frame = CGRect(x: size.width * 0.08, y: 0, width: size.width * 0.84, height: size.height * 0.52)
        groundGlow.frame = CGRect(x: size.width * 0.25, y: size.height * 0.86, width: size.width * 0.5, height: size.height * 0.14)
        captionLabel.frame = CGRect(x: 0, y: size.height - 36, width: size.width, height: 22)

        drawTrunk()
        drawBranches()
        drawSpouseLinks()
        drawLeaves()
        bringSubviewToFront(captionLabel)
        // Draw order: glows, trunk/branches/leaves above, nodes (subviews) on top.
        for model in nodes {
            let node = ILFamilyTreeNodeView(model: model)
            let height = node.bounds.height
            node.frame = CGRect(x: model.center.x - model.width / 2, y: model.center.y - height / 2,
                                width: model.width, height: height)
            node.onTap = { [weak self] in self?.onMemberTapped?(model.id) }
            addSubview(node)
            nodeViews[model.id] = node
        }
    }

    /// Cheap update for selection / filter / search changes.
    func applyState(selectedID: String?, lineageIDs: Set<String>, alphas: [String: CGFloat]) {
        for (id, layer) in lineageLayers {
            layer.isHidden = !lineageIDs.contains(id)
        }
        for (id, node) in nodeViews {
            let isSelected = id == selectedID
            node.setSelectedAppearance(isSelected)
            node.alpha = alphas[id] ?? 1
            node.layer.zPosition = isSelected ? 5 : 2
        }
    }

    /// Re-rasterises label text after a pinch zoom so it stays crisp.
    func updateContentScale(_ scale: CGFloat) {
        subviews.forEach { applyScale(scale, to: $0) }
    }

    private func applyScale(_ scale: CGFloat, to view: UIView) {
        view.contentScaleFactor = scale
        view.subviews.forEach { applyScale(scale, to: $0) }
    }

    func center(of memberID: String) -> CGPoint? {
        layout.centers[memberID]
    }

    // MARK: - Drawing
    private func addShape(_ path: UIBezierPath, stroke: UIColor? = nil, fill: UIColor? = nil, width: CGFloat = 0) -> CAShapeLayer {
        let shape = CAShapeLayer()
        shape.path = path.cgPath
        shape.strokeColor = stroke?.cgColor
        shape.fillColor = fill?.cgColor
        shape.lineWidth = width
        shape.lineCap = .round
        layer.addSublayer(shape)
        drawnLayers.append(shape)
        return shape
    }

    private func drawTrunk() {
        let top = layout.trunkTop
        let bottom = layout.canvasSize.height
        // The founder sits left of the middle when they have a spouse, but the trunk's foot belongs
        // in the middle of the canvas (under the caption): lean the trunk from the founder to there.
        let base = layout.canvasSize.width / 2
        let lean = base - top.x
        let trunk = UIBezierPath()
        trunk.move(to: CGPoint(x: top.x - 10, y: top.y + 12))
        trunk.addCurve(to: CGPoint(x: base - 26, y: bottom),
                       controlPoint1: CGPoint(x: top.x - 8, y: top.y + (bottom - top.y) * 0.4),
                       controlPoint2: CGPoint(x: base - 12 - lean * 0.1, y: top.y + (bottom - top.y) * 0.75))
        trunk.addLine(to: CGPoint(x: base + 26, y: bottom))
        trunk.addCurve(to: CGPoint(x: top.x + 10, y: top.y + 12),
                       controlPoint1: CGPoint(x: base + 12 - lean * 0.1, y: top.y + (bottom - top.y) * 0.75),
                       controlPoint2: CGPoint(x: top.x + 8, y: top.y + (bottom - top.y) * 0.4))
        trunk.close()
        _ = addShape(trunk, fill: Tree.bark)

        let roots = UIBezierPath()
        let span = bottom - top.y
        for (dx, reach) in [(-64.0, 0.55), (72.0, 0.6), (-130.0, 0.85), (140.0, 0.9), (-20.0, 0.95), (28.0, 0.95)] {
            roots.move(to: CGPoint(x: top.x, y: top.y + span * 0.12))
            roots.addCurve(to: CGPoint(x: base + CGFloat(dx), y: top.y + span * CGFloat(reach)),
                           controlPoint1: CGPoint(x: top.x + lean * 0.3 + CGFloat(dx) * 0.1, y: top.y + span * 0.45),
                           controlPoint2: CGPoint(x: base + CGFloat(dx) * 0.6, y: top.y + span * 0.75))
        }
        let rootLayer = addShape(roots, stroke: Tree.bark, width: Metrics.trunkWidth)
        rootLayer.opacity = 0.75
    }

    private func drawBranches() {
        for branch in layout.branches {
            let curve = ILFamilyTreeLayout.curve(from: branch.from, to: branch.to)
            let path = UIBezierPath()
            path.move(to: curve.p0)
            path.addCurve(to: curve.p3, controlPoint1: curve.p1, controlPoint2: curve.p2)

            let width = ILFamilyTreeLayout.branchWidth(generation: branch.generation)
            _ = addShape(path, stroke: Tree.bark, width: width)
            _ = addShape(path, stroke: Tree.barkLight, width: width * Metrics.branchHighlightRatio)
            let lineage = addShape(
                path, stroke: Tree.gold,
                width: max(Metrics.lineageMinWidth, width * Metrics.lineageWidthRatio)
            )
            lineage.isHidden = true
            lineageLayers[branch.childID] = lineage
        }
    }

    private func drawSpouseLinks() {
        let path = UIBezierPath()
        for link in layout.spouseLinks {
            path.move(to: link.from)
            path.addLine(to: link.to)
        }
        let shape = addShape(path, stroke: Tree.brown, width: Metrics.spouseLineWidth)
        shape.lineDashPattern = Metrics.spouseDash
    }

    private func drawLeaves() {
        // One layer per (tone, alpha) pair — leaves share fill and opacity, so each group is one path.
        var groups: [Int: (path: UIBezierPath, alpha: CGFloat)] = [:]
        for leaf in layout.leaves {
            let key = leaf.tone * 10 + Int((leaf.alpha * 10).rounded())
            let ellipse = UIBezierPath(ovalIn: CGRect(x: -leaf.radiusX, y: -leaf.radiusY,
                                                      width: leaf.radiusX * 2, height: leaf.radiusY * 2))
            ellipse.apply(CGAffineTransform(rotationAngle: leaf.rotation)
                .concatenating(CGAffineTransform(translationX: leaf.center.x, y: leaf.center.y)))
            let group = groups[key] ?? (UIBezierPath(), leaf.alpha)
            group.path.append(ellipse)
            groups[key] = group
        }
        let palette = [Tree.leafDark, Tree.leafMid, Tree.forest, Tree.leafLight, Tree.forestLight]
        for (key, group) in groups {
            let shape = addShape(group.path, fill: palette[(key / 10) % palette.count])
            shape.opacity = Float(group.alpha)
        }
    }
}
