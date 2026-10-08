//
//  ILFamilyTreeMedallionView.swift
//  InnerLamp
//

import UIKit

/// Hexagon portrait medallion (gradient trim ring, cream mat, 72-tick ring, gradient plate, tiny
/// bust with collar notch) drawn as vector layers so it stays sharp at any zoom. Height is
/// `width × hexRatio`.
final class ILFamilyTreeMedallionView: UIView {

    private typealias Tree = ILColors.FamilyTree

    // MARK: - Properties
    private let trimLayer = CAGradientLayer()
    private let trimMask = CAShapeLayer()
    private let creamLayer = CAShapeLayer()
    private let ticksLayer = CAGradientLayer()
    private let ticksMask = CAShapeLayer()
    private let innerCreamLayer = CAShapeLayer()
    private let plateLayer = CAGradientLayer()
    private let plateMask = CAShapeLayer()
    private let garmentLayer = CAShapeLayer()
    private let collarLayer = CAShapeLayer()
    private let headLayer = CAShapeLayer()
    private let hairLayer = CAShapeLayer()
    private let hairStripesLayer = CAShapeLayer()
    private let hairStripesMask = CAShapeLayer()
    private var look: ILFamilyTreeMedallionLook?

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        [trimLayer, creamLayer, ticksLayer, innerCreamLayer, plateLayer].forEach { layer.addSublayer($0) }
        [garmentLayer, collarLayer, headLayer, hairLayer, hairStripesLayer].forEach { plateLayer.addSublayer($0) }

        trimLayer.mask = trimMask
        trimLayer.startPoint = CGPoint(x: 0, y: 0)
        trimLayer.endPoint = CGPoint(x: 1, y: 1)

        ticksLayer.type = .conic
        ticksLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        ticksLayer.endPoint = CGPoint(x: 0.5, y: 0)
        ticksLayer.mask = ticksMask

        plateLayer.startPoint = CGPoint(x: 0.5, y: 0)
        plateLayer.endPoint = CGPoint(x: 0.5, y: 1)
        plateLayer.mask = plateMask

        hairStripesLayer.fillColor = nil
        hairStripesLayer.lineWidth = 1.5
        hairStripesLayer.mask = hairStripesMask

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILFamilyTreeMedallionView, _) in
            view.applyColors()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    func configure(with look: ILFamilyTreeMedallionLook) {
        self.look = look
        applyColors()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let metrics = ILMetrics.FamilyTree.self
        let outer = bounds
        [trimLayer, ticksLayer].forEach { $0.frame = outer }
        trimMask.path = Self.hexagon(in: outer).cgPath
        creamLayer.path = Self.hexagon(in: outer.insetBy(dx: metrics.medallionCreamInset, dy: metrics.medallionCreamInset)).cgPath
        ticksMask.path = Self.hexagon(in: outer.insetBy(dx: metrics.medallionTicksInset, dy: metrics.medallionTicksInset)).cgPath
        innerCreamLayer.path = Self.hexagon(in: outer.insetBy(dx: metrics.medallionInnerCreamInset, dy: metrics.medallionInnerCreamInset)).cgPath

        let plate = outer.insetBy(dx: metrics.medallionPlateInset, dy: metrics.medallionPlateInset)
        plateLayer.frame = plate
        plateMask.path = Self.hexagon(in: CGRect(origin: .zero, size: plate.size)).cgPath
        layoutBust(in: CGRect(origin: .zero, size: plate.size))
    }

    // MARK: - Drawing
    private func layoutBust(in rect: CGRect) {
        let w = rect.width, h = rect.height
        [hairStripesLayer, hairStripesMask].forEach { $0.frame = rect }
        let garment = CGRect(x: w * 0.11, y: h * 0.62, width: w * 0.78, height: w * 0.78 / 1.5)
        garmentLayer.path = UIBezierPath(roundedRect: garment, byRoundingCorners: [.topLeft, .topRight],
                                         cornerRadii: CGSize(width: garment.width / 2, height: garment.height * 0.7)).cgPath

        // Collar notch: a small downward triangle under the chin.
        let notch = CGRect(x: w * 0.44, y: h * 0.61, width: w * 0.12, height: h * 0.09)
        let triangle = UIBezierPath()
        triangle.move(to: CGPoint(x: notch.minX, y: notch.minY))
        triangle.addLine(to: CGPoint(x: notch.maxX, y: notch.minY))
        triangle.addLine(to: CGPoint(x: notch.midX, y: notch.maxY))
        triangle.close()
        collarLayer.path = triangle.cgPath

        let headSize = w * 0.36
        headLayer.path = UIBezierPath(ovalIn: CGRect(x: w * 0.32, y: h * 0.28, width: headSize, height: headSize)).cgPath

        let hair = UIBezierPath()
        hairStripesLayer.isHidden = look?.gender == .female
        if look?.gender == .female {
            hair.append(UIBezierPath(ovalIn: CGRect(x: w * 0.41, y: h * 0.17, width: w * 0.18, height: w * 0.18)))
            hair.append(UIBezierPath(roundedRect: CGRect(x: w * 0.31, y: h * 0.26, width: w * 0.38, height: h * 0.11),
                                     cornerRadius: h * 0.05))
        } else {
            let hairRect = CGRect(x: w * 0.30, y: h * 0.24, width: w * 0.40, height: h * 0.11)
            hair.append(UIBezierPath(roundedRect: hairRect, cornerRadius: h * 0.04))
            layoutHairStripes(in: hairRect)
        }
        hairLayer.path = hair.cgPath
        hairStripesMask.path = hair.cgPath
    }

    /// Design: `repeating-linear-gradient(170deg, hair 0 2px, bark 2px 3.5px)` — thin light bands
    /// perpendicular to the 170° axis, drawn as strokes clipped to the hair shape.
    private func layoutHairStripes(in rect: CGRect) {
        let angle = 170 * CGFloat.pi / 180
        let axis = CGPoint(x: sin(angle), y: -cos(angle))
        let along = CGPoint(x: -axis.y, y: axis.x)
        let length = abs(rect.width * axis.x) + abs(rect.height * axis.y)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let origin = CGPoint(x: center.x - axis.x * length / 2, y: center.y - axis.y * length / 2)
        let path = UIBezierPath()
        var distance: CGFloat = 2.75
        while distance < length {
            let mid = CGPoint(x: origin.x + axis.x * distance, y: origin.y + axis.y * distance)
            path.move(to: CGPoint(x: mid.x - along.x * rect.width, y: mid.y - along.y * rect.width))
            path.addLine(to: CGPoint(x: mid.x + along.x * rect.width, y: mid.y + along.y * rect.width))
            distance += 3.5
        }
        hairStripesLayer.path = path.cgPath
    }

    private func applyColors() {
        guard let look else { return }
        let trim: [UIColor]
        let trimLocations: [NSNumber]
        if look.isFounder {
            trim = Tree.founderTrimStops
            trimLocations = [0, 0.5, 1]
        } else if look.isClanHead {
            trim = Tree.headTrimStops
            trimLocations = [0, 1]
        } else {
            let flat = look.isLiving ? Tree.forest : Tree.brown
            trim = [flat, flat]
            trimLocations = [0, 1]
        }
        let ticks = look.isFounder ? Tree.ticksFounder : look.isLiving ? Tree.ticksLiving : Tree.ticksDeceased
        let plate = look.isFounder ? Tree.plateFounderGradient : look.isLiving ? Tree.plateLivingGradient : Tree.plateDeceasedGradient
        let garment: UIColor
        if look.isFounder {
            garment = Tree.garmentFounder
        } else if look.gender == .female {
            garment = look.isLiving ? Tree.garmentFemale : Tree.garmentFemaleDeceased
        } else {
            garment = look.isLiving ? Tree.garmentMaleLiving : Tree.garmentMaleDeceased
        }

        trimLayer.colors = trim.map { $0.resolvedColor(with: traitCollection).cgColor }
        trimLayer.locations = trimLocations
        creamLayer.fillColor = Tree.cream.resolvedColor(with: traitCollection).cgColor
        applyTicks(dark: ticks.dark, light: ticks.light)
        innerCreamLayer.fillColor = Tree.cream.resolvedColor(with: traitCollection).cgColor
        plateLayer.colors = plate.map { $0.resolvedColor(with: traitCollection).cgColor }
        garmentLayer.fillColor = garment.resolvedColor(with: traitCollection).cgColor
        collarLayer.fillColor = Tree.collarNotch.resolvedColor(with: traitCollection).cgColor
        headLayer.fillColor = Tree.skin.resolvedColor(with: traitCollection).cgColor
        hairLayer.fillColor = Tree.hair.resolvedColor(with: traitCollection).cgColor
        hairStripesLayer.strokeColor = Tree.hairStripe.resolvedColor(with: traitCollection).cgColor
        setNeedsLayout()
    }

    /// 72 alternating dark / light wedges (5° each) as hard stops of a conic gradient.
    private func applyTicks(dark: UIColor, light: UIColor) {
        let segments = ILMetrics.FamilyTree.tickCount
        let darkColor = dark.resolvedColor(with: traitCollection).cgColor
        let lightColor = light.resolvedColor(with: traitCollection).cgColor
        var colors: [CGColor] = []
        var locations: [NSNumber] = []
        for index in 0..<segments {
            let start = NSNumber(value: Double(index) / Double(segments))
            let end = NSNumber(value: Double(index + 1) / Double(segments))
            let color = index.isMultiple(of: 2) ? darkColor : lightColor
            colors += [color, color]
            locations += [start, end]
        }
        ticksLayer.colors = colors
        ticksLayer.locations = locations
    }

    /// Pointy-top hexagon matching the design's `polygon(50% 0, 100% 25%, 100% 75%, 50% 100%, 0 75%, 0 25%)`.
    static func hexagon(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.25))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.75))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.75))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.25))
        path.close()
        return path
    }
}
