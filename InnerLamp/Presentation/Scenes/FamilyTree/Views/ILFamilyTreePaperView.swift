//
//  ILFamilyTreePaperView.swift
//  InnerLamp
//

import UIKit

/// Screen background of the tree: parchment radial gradient, a faint two-layer dotted paper grain
/// and a soft green blob top-left. Purely decorative, never intercepts touches.
final class ILFamilyTreePaperView: UIView {

    private typealias Tree = ILColors.FamilyTree

    // MARK: - Properties
    private let gradientLayer = CAGradientLayer()
    private let fineGrainLayer = CALayer()
    private let coarseGrainLayer = CALayer()
    private let blobLayer = CAGradientLayer()

    /// CSS `radial-gradient(600px 500px at 30% 20%, …)`.
    private let gradientRadius = CGSize(width: 600, height: 500)
    private let gradientCenter = CGPoint(x: 0.3, y: 0.2)
    private let blobFrame = CGRect(x: -120, y: 40, width: 360, height: 300)

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = Tree.paperMid

        gradientLayer.type = .radial
        gradientLayer.colors = [Tree.paper.cgColor, Tree.paperMid.cgColor, Tree.paperEdge.cgColor]
        gradientLayer.locations = [0, 0.55, 1]
        gradientLayer.startPoint = gradientCenter
        layer.addSublayer(gradientLayer)

        blobLayer.type = .radial
        blobLayer.colors = [Tree.paperBlob.cgColor, Tree.paperBlob.withAlphaComponent(0).cgColor]
        blobLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        blobLayer.endPoint = CGPoint(x: 1, y: 1)
        blobLayer.frame = blobFrame
        layer.addSublayer(blobLayer)

        // Dots on a 6pt grid and an 11pt grid offset by (3, 5) — see the design's background-image stack.
        fineGrainLayer.backgroundColor = UIColor(patternImage: Self.dotTile(size: 6, dotAt: nil, color: Tree.grainFine)).cgColor
        coarseGrainLayer.backgroundColor = UIColor(patternImage: Self.dotTile(size: 11, dotAt: CGPoint(x: 3, y: 5), color: Tree.grainCoarse)).cgColor
        layer.addSublayer(fineGrainLayer)
        layer.addSublayer(coarseGrainLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        fineGrainLayer.frame = bounds
        coarseGrainLayer.frame = bounds
        guard bounds.width > 0, bounds.height > 0 else { return }
        gradientLayer.endPoint = CGPoint(
            x: gradientCenter.x + gradientRadius.width / bounds.width,
            y: gradientCenter.y + gradientRadius.height / bounds.height
        )
    }

    // MARK: - Tiles
    /// One repeating tile with a single dot. `dotAt == nil` centres a dot on every tile corner
    /// (CSS dot at the tile origin).
    private static func dotTile(size: CGFloat, dotAt: CGPoint?, color: UIColor) -> UIImage {
        let radius: CGFloat = 1.15
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { context in
            color.setFill()
            let centers = dotAt.map { [$0] } ?? [.zero, CGPoint(x: size, y: 0), CGPoint(x: 0, y: size), CGPoint(x: size, y: size)]
            for center in centers {
                context.cgContext.fillEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
            }
        }
    }
}
