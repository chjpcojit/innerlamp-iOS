//
//  ILPlayerArtworkView.swift
//  InnerLamp
//

import UIKit

/// The circular artwork of the full-screen player: a 196pt outer ring with a soft gold glow, a
/// 120pt inner ring, and a small flame — matches `player` in the design handoff
/// (`Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`). Feature-scoped because the
/// double-ring + centered-flame composition is specific to this screen (the shared
/// `ILLampGlowView` renders a single ring sized to a flame).
final class ILPlayerArtworkView: UIView {

    // MARK: - Layout constants (from the design handoff)
    private enum Artwork {
        static let outerDiameter: CGFloat = 196
        static let innerDiameter: CGFloat = 120
        static let flameHeight: CGFloat = 32
        static let flameBottomInset: CGFloat = 34
    }

    // MARK: - UI Elements
    private let outerRing = UIView()
    private let innerRing = UIView()
    private let glowLayer = CAGradientLayer()
    private let flameView = ILFlameView(height: Artwork.flameHeight, topColor: ILColors.goldBright)

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear

        outerRing.translatesAutoresizingMaskIntoConstraints = false
        outerRing.layer.borderWidth = 1
        outerRing.layer.borderColor = ILColors.goldRingBorder.cgColor
        outerRing.layer.cornerRadius = Artwork.outerDiameter / 2
        outerRing.clipsToBounds = false

        // Radial glow inside the outer ring (`radial-gradient(circle at 50% 58%, gold, transparent 68%)`).
        glowLayer.type = .radial
        glowLayer.colors = [ILColors.goldGlow.cgColor, ILColors.goldGlowClear.cgColor]
        glowLayer.locations = [0.0, 0.68]
        glowLayer.startPoint = CGPoint(x: 0.5, y: 0.58)
        glowLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        outerRing.layer.addSublayer(glowLayer)

        innerRing.translatesAutoresizingMaskIntoConstraints = false
        innerRing.layer.borderWidth = 1
        innerRing.layer.borderColor = ILColors.goldRingInnerBorder.cgColor
        innerRing.layer.cornerRadius = Artwork.innerDiameter / 2

        flameView.translatesAutoresizingMaskIntoConstraints = false

        outerRing.addSubview(innerRing)
        outerRing.addSubview(flameView)
        addSubview(outerRing)

        NSLayoutConstraint.activate([
            // Pin all four edges so the view's own size is the ring's — otherwise the stack view
            // collapses it to zero height and the title overlaps the artwork.
            outerRing.topAnchor.constraint(equalTo: topAnchor),
            outerRing.bottomAnchor.constraint(equalTo: bottomAnchor),
            outerRing.leadingAnchor.constraint(equalTo: leadingAnchor),
            outerRing.trailingAnchor.constraint(equalTo: trailingAnchor),
            outerRing.widthAnchor.constraint(equalToConstant: Artwork.outerDiameter),
            outerRing.heightAnchor.constraint(equalToConstant: Artwork.outerDiameter),

            innerRing.centerXAnchor.constraint(equalTo: outerRing.centerXAnchor),
            innerRing.centerYAnchor.constraint(equalTo: outerRing.centerYAnchor),
            innerRing.widthAnchor.constraint(equalToConstant: Artwork.innerDiameter),
            innerRing.heightAnchor.constraint(equalToConstant: Artwork.innerDiameter),

            flameView.centerXAnchor.constraint(equalTo: innerRing.centerXAnchor),
            flameView.bottomAnchor.constraint(equalTo: innerRing.bottomAnchor, constant: -Artwork.flameBottomInset),
            flameView.heightAnchor.constraint(equalToConstant: Artwork.flameHeight)
        ])
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILPlayerArtworkView, _) in
            view.applyColorAppearanceChange()
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        glowLayer.frame = outerRing.bounds
    }

    // `CAShapeLayer`/`CAGradientLayer` CGColors are static — refresh when light/dark flips.
    private func applyColorAppearanceChange() {
        outerRing.layer.borderColor = ILColors.goldRingBorder.cgColor
        innerRing.layer.borderColor = ILColors.goldRingInnerBorder.cgColor
        glowLayer.colors = [ILColors.goldGlow.cgColor, ILColors.goldGlowClear.cgColor]
    }
}
