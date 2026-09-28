//
//  ILBreathingRingView.swift
//  InnerLamp
//

import UIKit

/// Breathing ring of an immersive screen (design handoff `session`): an outlined outer ring, an
/// inner outlined ring with a radial halo, an innermost halo, and two centered lines of text (a
/// large countdown + a caption). The rings expand/contract with the breath via
/// `animateBreath(expanded:duration:)` (scale 1 → 1.12 in the design) while the text stays still.
///
/// Depends only on two strings and a breath direction, so it lives in the Design System.
public final class ILBreathingRingView: UIView {

    // MARK: - Properties
    public var timerText: String = "" {
        didSet { updateTimerText() }
    }

    public var captionText: String = "" {
        didSet { captionLabel.text = captionText }
    }

    /// Scale of the rings at the top of an inhale (design: `scale(1.12)`).
    public var expandedScale: CGFloat = 1.12

    private let diameter: CGFloat

    // MARK: - UI Elements
    /// Everything that breathes — the text is kept outside so it never scales.
    private let ringContainer = UIView()
    private let outerRing = UIView()
    private let innerRing = UIView()
    private let innerHaloLayer = CAGradientLayer()
    private let coreHalo = UIView()
    private let coreHaloLayer = CAGradientLayer()

    private let timerLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.immersiveTimer
        label.textColor = ILColors.medInk
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        return label
    }()

    private let captionLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.note
        label.textColor = ILColors.medInkTertiary
        label.textAlignment = .center
        return label
    }()

    // MARK: - Initializer
    public init(diameter: CGFloat = ILMetrics.breathingRingDiameter) {
        self.diameter = diameter
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        isAccessibilityElement = true
        accessibilityTraits = .updatesFrequently

        ringContainer.isUserInteractionEnabled = false
        addSubview(ringContainer)

        outerRing.layer.borderWidth = 1
        ringContainer.addSubview(outerRing)

        // `radial-gradient(circle at 50% 55%, halo, transparent 68%)`
        configureHalo(innerHaloLayer, center: CGPoint(x: 0.5, y: 0.55), stop: 0.68)
        innerRing.layer.borderWidth = 1
        innerRing.clipsToBounds = true
        innerRing.layer.addSublayer(innerHaloLayer)
        ringContainer.addSubview(innerRing)

        // `radial-gradient(circle at 50% 60%, halo, transparent 70%)`
        configureHalo(coreHaloLayer, center: CGPoint(x: 0.5, y: 0.60), stop: 0.70)
        coreHalo.clipsToBounds = true
        coreHalo.layer.addSublayer(coreHaloLayer)
        ringContainer.addSubview(coreHalo)

        let textStack = UIStackView(arrangedSubviews: [timerLabel, captionLabel])
        textStack.axis = .vertical
        textStack.alignment = .center
        textStack.spacing = ILMetrics.spaceSmall
        addSubview(textStack)

        [ringContainer, outerRing, innerRing, coreHalo, textStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        let innerInset = ILMetrics.breathingRingInnerInset
        let coreInset = ILMetrics.breathingRingCoreInset

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: diameter),
            heightAnchor.constraint(equalToConstant: diameter),

            ringContainer.topAnchor.constraint(equalTo: topAnchor),
            ringContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            ringContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            ringContainer.trailingAnchor.constraint(equalTo: trailingAnchor),

            outerRing.topAnchor.constraint(equalTo: ringContainer.topAnchor),
            outerRing.bottomAnchor.constraint(equalTo: ringContainer.bottomAnchor),
            outerRing.leadingAnchor.constraint(equalTo: ringContainer.leadingAnchor),
            outerRing.trailingAnchor.constraint(equalTo: ringContainer.trailingAnchor),

            innerRing.topAnchor.constraint(equalTo: ringContainer.topAnchor, constant: innerInset),
            innerRing.bottomAnchor.constraint(equalTo: ringContainer.bottomAnchor, constant: -innerInset),
            innerRing.leadingAnchor.constraint(equalTo: ringContainer.leadingAnchor, constant: innerInset),
            innerRing.trailingAnchor.constraint(equalTo: ringContainer.trailingAnchor, constant: -innerInset),

            coreHalo.topAnchor.constraint(equalTo: ringContainer.topAnchor, constant: coreInset),
            coreHalo.bottomAnchor.constraint(equalTo: ringContainer.bottomAnchor, constant: -coreInset),
            coreHalo.leadingAnchor.constraint(equalTo: ringContainer.leadingAnchor, constant: coreInset),
            coreHalo.trailingAnchor.constraint(equalTo: ringContainer.trailingAnchor, constant: -coreInset),

            textStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            textStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            textStack.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -2 * innerInset)
        ])

        applyColors()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILBreathingRingView, _) in
            view.applyColorAppearanceChange()
        }
    }

    /// Mirrors a CSS `radial-gradient(circle at <center>, halo, transparent <stop>)` sized to the
    /// farthest corner: `CAGradientLayer.radial` reads its radius from `endPoint - startPoint`.
    private func configureHalo(_ layer: CAGradientLayer, center: CGPoint, stop: CGFloat) {
        let farthestCorner = hypot(max(center.x, 1 - center.x), max(center.y, 1 - center.y))
        let radius = farthestCorner * stop
        layer.type = .radial
        layer.startPoint = center
        layer.endPoint = CGPoint(x: center.x + radius, y: center.y + radius)
        layer.locations = [0, 1]
    }

    // MARK: - Layout
    public override func layoutSubviews() {
        super.layoutSubviews()
        outerRing.layer.cornerRadius = outerRing.bounds.width / 2
        innerRing.layer.cornerRadius = innerRing.bounds.width / 2
        coreHalo.layer.cornerRadius = coreHalo.bounds.width / 2
        innerHaloLayer.frame = innerRing.bounds
        coreHaloLayer.frame = coreHalo.bounds
    }

    private func applyColorAppearanceChange() {
        applyColors()
    }

    // `borderColor` / gradient `colors` are static CGColors that don't follow the trait — resolve
    // them manually against the current appearance.
    private func applyColors() {
        outerRing.layer.borderColor = ILColors.medRing.resolvedColor(with: traitCollection).cgColor
        innerRing.layer.borderColor = ILColors.medRingStrong.resolvedColor(with: traitCollection).cgColor
        let haloColors = [
            ILColors.medHalo.resolvedColor(with: traitCollection).cgColor,
            ILColors.goldGlowClear.cgColor
        ]
        innerHaloLayer.colors = haloColors
        coreHaloLayer.colors = haloColors
    }

    private func updateTimerText() {
        // Design: `letter-spacing: -.02em` on the countdown.
        timerLabel.attributedText = NSAttributedString(
            string: timerText,
            attributes: [.kern: -0.02 * ILTypography.immersiveTimer.pointSize]
        )
        accessibilityLabel = timerText
    }

    public override var accessibilityValue: String? {
        get { captionText }
        set { super.accessibilityValue = newValue }
    }

    // MARK: - Breathing
    /// Animates the rings toward the inhale (`expanded = true`) or exhale size over `duration`,
    /// starting from wherever they currently are — so it can resume mid-breath after a pause.
    public func animateBreath(expanded: Bool, duration: TimeInterval) {
        let target = expanded ? expandedScale : 1
        guard !UIAccessibility.isReduceMotionEnabled else {
            ringContainer.transform = .identity
            return
        }
        freezeAtCurrentScale()
        UIView.animate(
            withDuration: max(duration, 0),
            delay: 0,
            options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction]
        ) {
            self.ringContainer.transform = CGAffineTransform(scaleX: target, y: target)
        }
    }

    /// Stops the rings where they are (session paused).
    public func pauseBreath() {
        freezeAtCurrentScale()
    }

    private func freezeAtCurrentScale() {
        let current = ringContainer.layer.presentation()?.affineTransform() ?? ringContainer.transform
        ringContainer.layer.removeAllAnimations()
        ringContainer.transform = current
    }
}
