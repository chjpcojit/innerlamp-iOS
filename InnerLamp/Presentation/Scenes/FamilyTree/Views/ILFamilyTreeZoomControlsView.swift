//
//  ILFamilyTreeZoomControlsView.swift
//  InnerLamp
//

import UIKit

/// Floating stack of round-rect buttons over the canvas: zoom in, zoom out, (gold) back to "me"
/// when the viewer is in the tree, back to the root.
final class ILFamilyTreeZoomControlsView: UIView {

    private typealias Tree = ILColors.FamilyTree
    private typealias Metrics = ILMetrics.FamilyTree

    // MARK: - Properties
    var onZoomIn: (() -> Void)?
    var onZoomOut: (() -> Void)?
    var onRoot: (() -> Void)?
    var onMe: (() -> Void)?

    /// Shows the gold "me" button between zoom-out and root.
    var showsMe = false {
        didSet { meButton.isHidden = !showsMe }
    }

    private let zoomInButton = ControlButton(title: "+", accessibilityID: "familyTree.zoomIn")
    private let zoomOutButton = ControlButton(title: "−", accessibilityID: "familyTree.zoomOut")
    private let meButton = ControlButton(title: nil, accessibilityID: "familyTree.me")
    private let rootButton = ControlButton(title: nil, accessibilityID: "familyTree.root")

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        zoomInButton.addTarget(self, action: #selector(handleZoomIn), for: .touchUpInside)
        zoomOutButton.addTarget(self, action: #selector(handleZoomOut), for: .touchUpInside)
        rootButton.addTarget(self, action: #selector(handleRoot), for: .touchUpInside)
        meButton.addTarget(self, action: #selector(handleMe), for: .touchUpInside)
        meButton.accessibilityLabel = "familyTree.zoom.me".localized
        meButton.isMe = true
        meButton.isHidden = true
        rootButton.accessibilityLabel = "familyTree.zoom.root".localized
        zoomInButton.accessibilityLabel = "familyTree.zoom.in".localized
        zoomOutButton.accessibilityLabel = "familyTree.zoom.out".localized
        rootButton.isRoot = true

        let stack = UIStackView(arrangedSubviews: [zoomInButton, zoomOutButton, meButton, rootButton])
        stack.axis = .vertical
        stack.spacing = Metrics.controlSpacing
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

    func setEnabled(canZoomIn: Bool, canZoomOut: Bool) {
        zoomInButton.isEnabled = canZoomIn
        zoomOutButton.isEnabled = canZoomOut
    }

    @objc private func handleZoomIn() { onZoomIn?() }
    @objc private func handleZoomOut() { onZoomOut?() }
    @objc private func handleRoot() { onRoot?() }
    @objc private func handleMe() { onMe?() }

    // MARK: - Button
    private final class ControlButton: UIControl {
        var isRoot = false {
            didSet { applyStyle(); rootGlyphLayer.isHidden = !isRoot }
        }
        /// Gold person-glyph button that jumps to the viewer.
        var isMe = false {
            didSet {
                iconView.image = isMe ? ILIcons.personViewer : nil
                applyStyle()
            }
        }
        private let titleLabel = UILabel()
        private let iconView = UIImageView()
        /// Little tree glyph on the "root" button. A shape layer, not `draw(_:)`: a drawn view gets
        /// its own backing bitmap, which painted a square block behind the rounded corners.
        private let rootGlyphLayer = CAShapeLayer()

        init(title: String?, accessibilityID: String) {
            super.init(frame: .zero)
            isOpaque = false
            accessibilityIdentifier = accessibilityID
            accessibilityTraits = .button
            layer.cornerRadius = Metrics.controlRadius
            layer.borderWidth = 1
            // Design `box-shadow: 0 4px 10px -6px`: blur 10 (radius 5), spread -6 via `shadowPath`.
            layer.shadowRadius = Metrics.controlShadowBlur
            layer.shadowOffset = CGSize(width: 0, height: Metrics.controlShadowOffsetY)
            titleLabel.text = title
            titleLabel.font = ILTypography.directionGlyph
            titleLabel.textAlignment = .center
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.isUserInteractionEnabled = false
            addSubview(titleLabel)
            iconView.contentMode = .scaleAspectFit
            iconView.translatesAutoresizingMaskIntoConstraints = false
            iconView.isUserInteractionEnabled = false
            addSubview(iconView)
            rootGlyphLayer.fillColor = nil
            rootGlyphLayer.lineWidth = 1.7
            rootGlyphLayer.lineCap = .round
            rootGlyphLayer.isHidden = true
            layer.addSublayer(rootGlyphLayer)
            NSLayoutConstraint.activate([
                iconView.widthAnchor.constraint(equalToConstant: Metrics.controlIconSize),
                iconView.heightAnchor.constraint(equalToConstant: Metrics.controlIconSize),
                iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
                iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
                widthAnchor.constraint(equalToConstant: Metrics.controlSize),
                heightAnchor.constraint(equalToConstant: Metrics.controlSize),
                titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
                titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
            applyStyle()
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ControlButton, _) in
                view.applyStyle()
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var isEnabled: Bool {
            didSet { alpha = isEnabled ? 1 : 0.4 }
        }

        override var isHighlighted: Bool {
            didSet { alpha = isEnabled ? (isHighlighted ? 0.7 : 1) : 0.4 }
        }

        private func applyStyle() {
            let isFilled = isRoot || isMe
            backgroundColor = isMe ? Tree.me : (isRoot ? Tree.forest : Tree.controlSurface)
            layer.borderColor = (isFilled ? UIColor.clear : Tree.controlBorder).cgColor
            titleLabel.textColor = Tree.ink
            iconView.tintColor = Tree.inkOnMe
            rootGlyphLayer.strokeColor = Tree.cream.cgColor
            layer.shadowColor = (isRoot ? Tree.forest : Tree.shadow).cgColor
            layer.shadowOpacity = isRoot ? 0.8 : (isMe ? 0.7 : 0.5)
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            layer.shadowPath = UIBezierPath(
                roundedRect: bounds.insetBy(dx: Metrics.controlShadowSpread, dy: Metrics.controlShadowSpread),
                cornerRadius: Metrics.controlRadius
            ).cgPath
            rootGlyphLayer.frame = bounds
            rootGlyphLayer.path = Self.rootGlyphPath(in: bounds).cgPath
        }

        private static func rootGlyphPath(in bounds: CGRect) -> UIBezierPath {
            let c = CGPoint(x: bounds.midX, y: bounds.midY)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: c.x, y: c.y - 8))
            path.addLine(to: CGPoint(x: c.x, y: c.y + 2))
            path.move(to: CGPoint(x: c.x, y: c.y + 2))
            path.addQuadCurve(to: CGPoint(x: c.x - 5, y: c.y + 8), controlPoint: CGPoint(x: c.x - 2, y: c.y + 4))
            path.move(to: CGPoint(x: c.x, y: c.y + 2))
            path.addQuadCurve(to: CGPoint(x: c.x + 5, y: c.y + 8), controlPoint: CGPoint(x: c.x + 2, y: c.y + 4))
            path.move(to: CGPoint(x: c.x, y: c.y + 2))
            path.addLine(to: CGPoint(x: c.x, y: c.y + 8))
            return path
        }
    }
}
