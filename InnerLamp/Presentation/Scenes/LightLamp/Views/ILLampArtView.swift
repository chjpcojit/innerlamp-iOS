//
//  ILLampArtView.swift
//  InnerLamp
//

import UIKit

/// Lamp illustration (design handoff `IL-LampArt`): an oil lamp, a lotus candle or a floating
/// lantern with a flame and a warm halo. Built from gradient layers — there is no raster asset —
/// and sized purely by its width: the height is `ILMetrics.Lamp.artHeightRatio × width`.
///
/// `setLit(_:animated:)` ignites (flame scales up from the wick, halo blooms) or extinguishes it.
/// Layout is manual (`layoutSubviews`) because the flame needs a bottom `anchorPoint`.
final class ILLampArtView: UIView {

    // MARK: - Part model
    /// Fractions of the art width; `radii` are (rx as a fraction of the part width, ry as a
    /// fraction of its height) for the TL, TR, BR, BL corners — the CSS `border-radius: a / b` form.
    private struct Part {
        enum Fill {
            case solid(UIColor)
            case vertical(UIColor, UIColor)
            case horizontal([UIColor])
        }

        let width: CGFloat
        let height: CGFloat
        let bottom: CGFloat
        let radii: [CGSize]
        let fill: Fill
        var rotation: CGFloat = 0
    }

    private static let ellipse = Array(repeating: CGSize(width: 0.5, height: 0.5), count: 4)

    // MARK: - Properties
    var kind: ILLampKind {
        didSet {
            guard kind != oldValue else { return }
            rebuildParts()
        }
    }

    private(set) var isLit: Bool
    private let showsRipple: Bool

    // MARK: - Layers & views
    private lazy var haloView: UIView = {
        let view = UIView()
        return view
    }()

    private let haloLayer = CAGradientLayer()

    private lazy var flameView: UIView = {
        let view = UIView()
        view.layer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        view.layer.shadowColor = ILColors.goldBright.cgColor
        view.layer.shadowOpacity = 0.8
        view.layer.shadowOffset = .zero
        return view
    }()

    private lazy var flameImage: UIImageView = {
        let imageView = UIImageView(image: ILIcons.tabLampFlame)
        imageView.tintColor = ILColors.Lamp.flameOuter
        imageView.contentMode = .scaleToFill
        return imageView
    }()

    private lazy var coreImage: UIImageView = {
        let imageView = UIImageView(image: ILIcons.tabLampCore)
        imageView.tintColor = ILColors.Lamp.flameCore
        imageView.contentMode = .scaleToFill
        return imageView
    }()
    private let rippleInner = CAShapeLayer()
    private let rippleOuter = CAShapeLayer()
    private var partLayers: [CAGradientLayer] = []
    private var parts: [Part] = []
    private var flameBottom: CGFloat = 0.46

    // MARK: - Initializer
    init(kind: ILLampKind, isLit: Bool = true, showsRipple: Bool = false) {
        self.kind = kind
        self.isLit = isLit
        self.showsRipple = showsRipple
        super.init(frame: .zero)
        setupViews()
        rebuildParts()
        applyLitState()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        isUserInteractionEnabled = false
        backgroundColor = .clear

        haloLayer.type = .radial
        haloLayer.colors = [
            ILColors.Lamp.haloCore.cgColor,
            ILColors.Lamp.haloMid.cgColor,
            ILColors.goldGlowClear.cgColor
        ]
        haloLayer.locations = [0.0, 0.45, 0.7]
        haloLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        haloLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        haloView.layer.addSublayer(haloLayer)
        addSubview(haloView)

        if showsRipple {
            [rippleInner, rippleOuter].forEach {
                $0.fillColor = UIColor.clear.cgColor
                $0.lineWidth = 1
                layer.addSublayer($0)
            }
            rippleInner.strokeColor = ILColors.Lamp.rippleInner.cgColor
            rippleOuter.strokeColor = ILColors.Lamp.rippleOuter.cgColor
        }

        [flameImage, coreImage].forEach { flameView.addSubview($0) }
        addSubview(flameView)
    }

    private func rebuildParts() {
        partLayers.forEach { $0.removeFromSuperlayer() }
        partLayers = []

        let palette = ILColors.Lamp.self
        switch kind {
        case .oil:
            flameBottom = 0.46
            parts = [
                Part(width: 0.46, height: 0.07, bottom: 0, radii: Self.ellipse,
                     fill: .vertical(palette.oilBaseTop, palette.oilBaseBottom)),
                Part(width: 0.12, height: 0.15, bottom: 0.06,
                     radii: Array(repeating: CGSize(width: 0.1, height: 0.1), count: 4),
                     fill: .horizontal([palette.oilStemMid, palette.oilStemLight, palette.oilStemDark])),
                // Bowl: flat top, half-ellipse bottom (`0 0 50% 50% / 0 0 100% 100%`).
                Part(width: 0.8, height: 0.27, bottom: 0.2,
                     radii: [.zero, .zero, CGSize(width: 0.5, height: 1), CGSize(width: 0.5, height: 1)],
                     fill: .vertical(palette.oilBowlTop, palette.oilStemDark)),
                Part(width: 0.8, height: 0.08, bottom: 0.43, radii: Self.ellipse, fill: .solid(palette.oilRim))
            ]
        case .lotus:
            flameBottom = 0.48
            parts = [
                Part(width: 0.7, height: 0.12, bottom: 0.02, radii: Self.ellipse,
                     fill: .vertical(palette.lotusBaseTop, palette.lotusBaseBottom)),
                Part(width: 0.656, height: 0.42, bottom: 0.08,
                     radii: [CGSize(width: 0.4, height: 0.16), CGSize(width: 0.4, height: 0.16),
                             CGSize(width: 0.48, height: 0.5), CGSize(width: 0.48, height: 0.5)],
                     fill: .vertical(palette.lotusPetalTop, palette.lotusPetalBottom)),
                Part(width: 0.5, height: 0.07, bottom: 0.46, radii: Self.ellipse, fill: .solid(palette.lotusTop))
            ]
        case .float:
            flameBottom = 0.38
            let petalRadii = [CGSize(width: 0.5, height: 0.8), CGSize(width: 0.5, height: 0.8),
                              CGSize(width: 0.5, height: 0.2), CGSize(width: 0.5, height: 0.2)]
            let petal = Part.Fill.vertical(palette.floatPetalTop, palette.floatPetalBottom)
            parts = [
                Part(width: 0.22, height: 0.22, bottom: 0.27, radii: petalRadii, fill: petal, rotation: -38),
                Part(width: 0.22, height: 0.22, bottom: 0.27, radii: petalRadii, fill: petal, rotation: 38),
                Part(width: 0.92, height: 0.24, bottom: 0.1,
                     radii: [CGSize(width: 0.46, height: 0.34), CGSize(width: 0.46, height: 0.34),
                             CGSize(width: 0.5, height: 0.66), CGSize(width: 0.5, height: 0.66)],
                     fill: .vertical(palette.floatBoatTop, palette.floatBoatBottom)),
                Part(width: 0.22, height: 0.26, bottom: 0.28, radii: petalRadii, fill: petal)
            ]
        }

        for part in parts {
            let gradient = CAGradientLayer()
            gradient.mask = CAShapeLayer()
            switch part.fill {
            case .solid(let color):
                gradient.colors = [color.cgColor, color.cgColor]
            case .vertical(let top, let bottom):
                gradient.colors = [top.cgColor, bottom.cgColor]
                gradient.startPoint = CGPoint(x: 0.5, y: 0)
                gradient.endPoint = CGPoint(x: 0.5, y: 1)
            case .horizontal(let colors):
                gradient.colors = colors.map(\.cgColor)
                gradient.startPoint = CGPoint(x: 0, y: 0.5)
                gradient.endPoint = CGPoint(x: 1, y: 0.5)
            }
            gradient.anchorPoint = CGPoint(x: 0.5, y: 1.0)
            // Parts sit below the flame and halo views.
            layer.insertSublayer(gradient, below: flameView.layer)
            partLayers.append(gradient)
        }
        // Ripples exist only under the floating lantern.
        rippleInner.isHidden = kind != .float
        rippleOuter.isHidden = kind != .float
        setNeedsLayout()
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        let width = bounds.width
        let height = bounds.height
        guard width > 0 else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }

        for (layer, part) in zip(partLayers, parts) {
            let size = CGSize(width: part.width * width, height: part.height * width)
            layer.bounds = CGRect(origin: .zero, size: size)
            layer.position = CGPoint(x: width / 2, y: height - part.bottom * width)
            layer.transform = CATransform3DMakeRotation(part.rotation * .pi / 180, 0, 0, 1)
            if let mask = layer.mask as? CAShapeLayer {
                mask.frame = layer.bounds
                mask.path = Self.path(in: layer.bounds, radii: part.radii)
            }
        }

        let haloSide = 1.15 * width
        haloView.transform = .identity
        haloView.frame = CGRect(
            x: width / 2 - haloSide / 2,
            y: height - (flameBottom - 0.32) * width - haloSide,
            width: haloSide,
            height: haloSide
        )
        haloLayer.frame = haloView.bounds

        let flameSize = CGSize(width: 0.3 * width, height: 0.42 * width)
        flameView.transform = .identity
        flameView.bounds = CGRect(origin: .zero, size: flameSize)
        flameView.layer.position = CGPoint(x: width / 2, y: height - flameBottom * width)
        flameImage.frame = flameView.bounds
        coreImage.frame = flameView.bounds
        flameView.layer.shadowRadius = 0.3 * width * 0.15
        applyLitState()

        if showsRipple {
            rippleInner.path = CGPath(
                ellipseIn: CGRect(x: 0, y: height - 0.12 * width, width: width, height: 0.12 * width), transform: nil
            )
            rippleOuter.path = CGPath(
                ellipseIn: CGRect(x: -0.125 * width, y: height - 0.16 * width + 0.02 * width,
                                  width: 1.25 * width, height: 0.16 * width),
                transform: nil
            )
        }
    }

    // MARK: - Lit state
    func setLit(_ lit: Bool, animated: Bool) {
        guard lit != isLit else { return }
        isLit = lit
        guard animated, !UIAccessibility.isReduceMotionEnabled else {
            applyLitState()
            return
        }
        let animator = UIViewPropertyAnimator(
            duration: ILMetrics.Lamp.ignitedDuration,
            controlPoint1: CGPoint(x: 0.2, y: 0.7),
            controlPoint2: CGPoint(x: 0.2, y: 1.0)
        ) { [weak self] in
            self?.applyLitState()
        }
        animator.startAnimation()
    }

    private func applyLitState() {
        flameView.transform = isLit ? .identity : CGAffineTransform(scaleX: 0.06, y: 0.06)
        flameView.alpha = isLit ? 1 : 0
        haloView.transform = isLit ? .identity : CGAffineTransform(scaleX: 0.2, y: 0.2)
        haloView.alpha = isLit ? 1 : 0
    }

    // MARK: - Path
    /// Rounded rect with an independent elliptical radius per corner (TL, TR, BR, BL), radii given
    /// as fractions of the rect's width/height.
    private static func path(in rect: CGRect, radii: [CGSize]) -> CGPath {
        guard radii.count == 4 else { return CGPath(rect: rect, transform: nil) }
        let corners = radii.map { CGSize(width: $0.width * rect.width, height: $0.height * rect.height) }
        let tl = corners[0], tr = corners[1], br = corners[2], bl = corners[3]
        let k: CGFloat = 0.5523
        let path = CGMutablePath()
        path.move(to: CGPoint(x: rect.minX + tl.width, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - tr.width, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + tr.height),
            control1: CGPoint(x: rect.maxX - tr.width + k * tr.width, y: rect.minY),
            control2: CGPoint(x: rect.maxX, y: rect.minY + tr.height - k * tr.height)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br.height))
        path.addCurve(
            to: CGPoint(x: rect.maxX - br.width, y: rect.maxY),
            control1: CGPoint(x: rect.maxX, y: rect.maxY - br.height + k * br.height),
            control2: CGPoint(x: rect.maxX - br.width + k * br.width, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + bl.width, y: rect.maxY))
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - bl.height),
            control1: CGPoint(x: rect.minX + bl.width - k * bl.width, y: rect.maxY),
            control2: CGPoint(x: rect.minX, y: rect.maxY - bl.height + k * bl.height)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl.height))
        path.addCurve(
            to: CGPoint(x: rect.minX + tl.width, y: rect.minY),
            control1: CGPoint(x: rect.minX, y: rect.minY + tl.height - k * tl.height),
            control2: CGPoint(x: rect.minX + tl.width - k * tl.width, y: rect.minY)
        )
        path.closeSubpath()
        return path
    }
}
