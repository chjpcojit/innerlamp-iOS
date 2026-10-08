//
//  ILBellPadView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import UIKit

/// The center of the "Chuông mõ" screen: a stage showing the instrument photo (singing bowl or
/// wooden fish) with its mallet and a gold halo, then the running count + hint underneath. The
/// whole control is the strike target. `flashMo()` / `flashBell()` replay the design's strike
/// feedback (mallet swing, instrument bounce / ring-down, ripples, halo) for the `ViewController`.
final class ILBellPadView: UIControl {

    // MARK: - Properties
    var tagText: String = "" {
        didSet { tagLabel.attributedText = Self.attributedTag(tagText) }
    }

    var numberText: String = "" {
        didSet { numberLabel.text = numberText }
    }

    var hintText: String = "" {
        didSet { hintLabel.text = hintText }
    }

    /// Bell mode shows the singing bowl + striker; every other mode shows the wooden fish + mallet.
    var isBellShown: Bool = false {
        didSet {
            guard isBellShown != oldValue else { return }
            applyInstrument()
        }
    }

    var onTap: (() -> Void)?

    private var lastMoStrikeTime: CFTimeInterval?
    private var haloResetWorkItem: DispatchWorkItem?

    // MARK: - UI Elements
    private let stageView = UIView()
    private let haloView = UIView()
    private let haloGradient = CAGradientLayer()
    private let rippleHost = UIView()
    private let instrumentView = UIImageView()
    private let malletView = UIImageView()
    private let tagLabel = UILabel()
    private let numberLabel = UILabel()
    private let hintLabel = UILabel()

    // MARK: - Layout constants (design handoff, stage coordinates)
    private static let stageSize: CGFloat = 236
    private static let instrumentFrame = CGRect(x: 18, y: 18, width: 200, height: 200)
    private static let malletSize = CGSize(width: 34, height: 126)
    /// Bottom-center of the mallet stick — the pivot of its swing.
    private static let malletPivot = CGPoint(x: 226, y: 236)
    private static let malletRestAngle: CGFloat = -8
    private static let rippleFrame = CGRect(x: 34, y: 34, width: 168, height: 168)

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
        applyInstrument()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        stageView.isUserInteractionEnabled = false
        stageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stageView)

        // Halo — radial gold glow, invisible until a strike.
        haloGradient.type = .radial
        haloGradient.colors = [ILColors.medGoldHalo.cgColor, ILColors.medGoldHalo.withAlphaComponent(0).cgColor]
        haloGradient.startPoint = CGPoint(x: 0.5, y: 0.5)
        haloGradient.endPoint = CGPoint(x: 1, y: 1)
        haloGradient.locations = [0, 0.68]
        haloView.layer.addSublayer(haloGradient)
        haloView.alpha = 0
        haloView.frame = CGRect(x: 0, y: 0, width: Self.stageSize, height: Self.stageSize)
        haloGradient.frame = haloView.bounds
        stageView.addSubview(haloView)

        rippleHost.frame = haloView.frame
        stageView.addSubview(rippleHost)

        instrumentView.contentMode = .scaleAspectFit
        instrumentView.bounds = CGRect(origin: .zero, size: Self.instrumentFrame.size)
        instrumentView.layer.shadowColor = UIColor.black.cgColor
        instrumentView.layer.shadowOpacity = 0.5
        instrumentView.layer.shadowOffset = CGSize(width: 0, height: 14)
        instrumentView.layer.shadowRadius = 8
        stageView.addSubview(instrumentView)

        malletView.bounds = CGRect(origin: .zero, size: Self.malletSize)
        malletView.layer.anchorPoint = CGPoint(x: 0.5, y: 1)
        malletView.layer.position = Self.malletPivot
        malletView.transform = Self.malletRestTransform
        malletView.layer.shadowColor = UIColor.black.cgColor
        malletView.layer.shadowOpacity = 0.45
        malletView.layer.shadowOffset = CGSize(width: -3, height: 6)
        malletView.layer.shadowRadius = 3
        stageView.addSubview(malletView)

        numberLabel.font = ILTypography.bellPadNumber
        numberLabel.textColor = ILColors.medInk
        numberLabel.textAlignment = .center

        let readoutRow = UIStackView(arrangedSubviews: [tagLabel, numberLabel])
        readoutRow.axis = .horizontal
        readoutRow.alignment = .lastBaseline
        readoutRow.spacing = 8

        hintLabel.font = ILTypography.subhead
        hintLabel.textColor = ILColors.medInkTertiary
        hintLabel.textAlignment = .center

        let readoutStack = UIStackView(arrangedSubviews: [readoutRow, hintLabel])
        readoutStack.axis = .vertical
        readoutStack.alignment = .center
        readoutStack.spacing = 6
        readoutStack.isUserInteractionEnabled = false
        readoutStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(readoutStack)

        NSLayoutConstraint.activate([
            stageView.topAnchor.constraint(equalTo: topAnchor),
            stageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stageView.widthAnchor.constraint(equalToConstant: Self.stageSize),
            stageView.heightAnchor.constraint(equalToConstant: Self.stageSize),

            readoutStack.topAnchor.constraint(equalTo: stageView.bottomAnchor, constant: 10),
            readoutStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            readoutStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            readoutStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            readoutStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),

            widthAnchor.constraint(greaterThanOrEqualToConstant: Self.stageSize)
        ])

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        isAccessibilityElement = true
        accessibilityTraits = .button
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILBellPadView, _) in
            view.refreshLayerColors()
        }
    }

    private func refreshLayerColors() {
        haloGradient.colors = [ILColors.medGoldHalo.cgColor, ILColors.medGoldHalo.withAlphaComponent(0).cgColor]
    }

    /// Swap the photo + mallet head and re-pivot the instrument (the bowl hangs from its top, the
    /// wooden fish rocks on its base).
    private func applyInstrument() {
        instrumentView.image = isBellShown ? ILIcons.bellChuong : ILIcons.bellMo
        malletView.image = isBellShown ? ILIcons.bellMalletBell : ILIcons.bellMalletMo
        instrumentView.layer.removeAllAnimations()
        malletView.layer.removeAllAnimations()
        let frame = Self.instrumentFrame
        let anchorY: CGFloat = isBellShown ? 0.30 : 0.85
        instrumentView.layer.anchorPoint = CGPoint(x: 0.5, y: anchorY)
        instrumentView.layer.position = CGPoint(x: frame.midX, y: frame.minY + frame.height * anchorY)
        instrumentView.transform = .identity
        malletView.transform = Self.malletRestTransform
    }

    private static var malletRestTransform: CGAffineTransform {
        CGAffineTransform(rotationAngle: radians(malletRestAngle))
    }

    private static func radians(_ degrees: CGFloat) -> CGFloat {
        degrees * .pi / 180
    }

    // MARK: - Strike feedback
    /// Wooden-fish strike: mallet swings down, the fish dips and settles, one soft ripple, a faint halo.
    func flashMo() {
        let now = CACurrentMediaTime()
        // During the roll the strikes come faster than the swing is long — shorten it to match.
        let duration = lastMoStrikeTime.map { min(0.26, max(0.06, (now - $0) * 0.85)) } ?? 0.26
        lastMoStrikeTime = now

        if !isBellShown {
            swingMallet(offsets: [0, 0.1, 0.27, 0.5, 1], angles: [-8, 2, -37, -26, -8], duration: duration)
            dipInstrument(duration: duration)
        }
        addRipples(delays: [0.07], duration: 0.52, lineWidth: 1.5, color: ILColors.medGoldRippleMo, peak: 0.8, peakTime: 0.15, startPeakScale: 1.02, endScale: 1.24)
        pulseHalo(opacity: 0.55, scale: 1, resetAfter: 0.11)
    }

    /// Bell strike: striker swings, the bowl rings down, three expanding ripples, full halo swell.
    func flashBell() {
        if isBellShown {
            swingMallet(offsets: [0, 0.1, 0.15, 0.32, 1], angles: [-8, 2, -37, -26, -8], duration: 0.48)
            ringInstrument()
        }
        addRipples(delays: [0.07, 0.42, 0.82], duration: 2.6, lineWidth: 2, color: ILColors.medGoldRippleBell, peak: 0.7, peakTime: 0.08, startPeakScale: 1.05, endScale: 2)
        pulseHalo(opacity: 1, scale: 1.08, resetAfter: 0.42)
    }

    private func swingMallet(offsets: [Double], angles: [CGFloat], duration: CFTimeInterval) {
        let swing = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        swing.values = angles.map { Self.radians($0) }
        swing.keyTimes = offsets.map { NSNumber(value: $0) }
        swing.timingFunctions = Array(repeating: CAMediaTimingFunction(name: .easeOut), count: angles.count - 1)
        swing.duration = duration
        malletView.layer.add(swing, forKey: "swing")
    }

    private func dipInstrument(duration: CFTimeInterval) {
        func transform(scale: CGFloat, dx: CGFloat = 0, dy: CGFloat = 0) -> NSValue {
            let scaled = CATransform3DMakeScale(scale, scale, 1)
            return NSValue(caTransform3D: CATransform3DTranslate(scaled, dx, dy, 0))
        }
        let dip = CAKeyframeAnimation(keyPath: "transform")
        dip.values = [transform(scale: 1), transform(scale: 1), transform(scale: 0.962, dx: -2, dy: 2), transform(scale: 1.01), transform(scale: 1)]
        dip.keyTimes = [0, 0.27, 0.38, 0.62, 1]
        dip.timingFunctions = Array(repeating: CAMediaTimingFunction(name: .easeOut), count: 4)
        dip.duration = duration
        instrumentView.layer.add(dip, forKey: "strike")
    }

    /// Damped sway of the hanging bowl after the striker hits it (design: 2.2s, linear).
    private func ringInstrument() {
        let sway: [CGFloat] = [0, 0, 1.8, -1.5, 1.2, -0.95, 0.75, -0.55, 0.4, -0.28, 0.18, -0.1, 0]
        let count = Double(sway.count - 2)
        let ring = CAKeyframeAnimation(keyPath: "transform")
        ring.values = sway.map { degrees in
            let rotated = CATransform3DMakeRotation(Self.radians(degrees), 0, 0, 1)
            return NSValue(caTransform3D: CATransform3DTranslate(rotated, degrees * 0.6, 0, 0))
        }
        ring.keyTimes = sway.indices.map { index in
            NSNumber(value: index == 0 ? 0 : index == 1 ? 0.035 : 0.035 + Double(index - 1) / count * 0.965)
        }
        ring.duration = 2.2
        instrumentView.layer.add(ring, forKey: "strike")
    }

    private func addRipples(
        delays: [CFTimeInterval],
        duration: CFTimeInterval,
        lineWidth: CGFloat,
        color: UIColor,
        peak: Float,
        peakTime: Double,
        startPeakScale: CGFloat,
        endScale: CGFloat
    ) {
        for delay in delays {
            let ripple = CAShapeLayer()
            ripple.frame = Self.rippleFrame
            ripple.path = UIBezierPath(ovalIn: ripple.bounds.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)).cgPath
            ripple.fillColor = UIColor.clear.cgColor
            ripple.strokeColor = color.cgColor
            ripple.lineWidth = lineWidth
            ripple.opacity = 0
            rippleHost.layer.addSublayer(ripple)

            let scale = CAKeyframeAnimation(keyPath: "transform.scale")
            scale.values = [1, startPeakScale, endScale]
            scale.keyTimes = [0, NSNumber(value: peakTime), 1]
            let fade = CAKeyframeAnimation(keyPath: "opacity")
            fade.values = [0, peak, 0]
            fade.keyTimes = [0, NSNumber(value: peakTime), 1]
            let group = CAAnimationGroup()
            group.animations = [scale, fade]
            group.duration = duration
            group.beginTime = CACurrentMediaTime() + delay
            group.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.6, 0.3, 1)
            group.fillMode = .backwards

            CATransaction.begin()
            CATransaction.setCompletionBlock { [weak ripple] in ripple?.removeFromSuperlayer() }
            ripple.add(group, forKey: "ripple")
            CATransaction.commit()
        }
    }

    /// Halo flares on the strike and fades back (design: 0.5s ease, reset 110ms / 420ms later).
    private func pulseHalo(opacity: CGFloat, scale: CGFloat, resetAfter delay: TimeInterval) {
        haloResetWorkItem?.cancel()
        setHalo(opacity: opacity, scale: scale)
        let reset = DispatchWorkItem { [weak self] in self?.setHalo(opacity: 0, scale: 1) }
        haloResetWorkItem = reset
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: reset)
    }

    private func setHalo(opacity: CGFloat, scale: CGFloat) {
        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction]) {
            self.haloView.alpha = opacity
            self.haloView.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }

    @objc private func handleTap() {
        onTap?()
    }

    private static func attributedTag(_ text: String) -> NSAttributedString {
        ILTypography.makeAttributedString(
            text: text,
            font: ILTypography.eyebrowSmall,
            color: ILColors.medGold,
            letterSpacingEm: 0.16,
            alignment: .center
        )
    }
}
