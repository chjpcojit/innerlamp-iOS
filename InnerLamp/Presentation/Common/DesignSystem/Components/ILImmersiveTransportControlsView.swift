//
//  ILImmersiveTransportControlsView.swift
//  InnerLamp
//

import UIKit

/// Transport row at the bottom of an immersive screen (design handoff `session`): a ghost circle
/// button on the leading side (hollow-circle glyph — leave), a large gold play/pause button in the
/// middle with a glow, and a ghost circle button on the trailing side (square glyph — stop/end).
/// Colors come from the `--il-med-*` set so the row follows the immersive light/dark palette.
public final class ILImmersiveTransportControlsView: UIView {

    // MARK: - Properties
    public var isPlaying: Bool = true {
        didSet { updatePlayPauseButton() }
    }

    /// VoiceOver label of the primary button while playing (it pauses when tapped).
    public var pauseAccessibilityLabel: String = "" {
        didSet { updatePlayPauseButton() }
    }

    /// VoiceOver label of the primary button while paused (it resumes when tapped).
    public var playAccessibilityLabel: String = "" {
        didSet { updatePlayPauseButton() }
    }

    public var leadingAccessibilityLabel: String? {
        get { leadingButton.accessibilityLabel }
        set { leadingButton.accessibilityLabel = newValue }
    }

    public var trailingAccessibilityLabel: String? {
        get { trailingButton.accessibilityLabel }
        set { trailingButton.accessibilityLabel = newValue }
    }

    public var onLeadingTap: (() -> Void)?
    public var onPrimaryTap: (() -> Void)?
    public var onTrailingTap: (() -> Void)?

    // MARK: - UI Elements
    private let leadingButton = ILImmersiveGhostCircleButton(glyph: .ring)
    private let trailingButton = ILImmersiveGhostCircleButton(glyph: .square)

    private let playPauseButton = ILPlayPauseButton(
        diameter: ILMetrics.transportPrimaryButtonSize,
        glyphColor: ILColors.medOnGold,
        fillColor: ILColors.medGold,
        glyphScale: 1.5
    )

    /// Carries the glow — `ILPlayPauseButton` clips to its circle, which would cut the shadow off.
    private let glowContainer = UIView()

    // MARK: - Initializer
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        leadingButton.addTarget(self, action: #selector(handleLeadingTap), for: .touchUpInside)
        trailingButton.addTarget(self, action: #selector(handleTrailingTap), for: .touchUpInside)
        playPauseButton.onTap = { [weak self] in self?.onPrimaryTap?() }
        updatePlayPauseButton()

        glowContainer.addSubview(playPauseButton)
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [leadingButton, glowContainer, trailingButton])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = ILMetrics.transportSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),

            playPauseButton.topAnchor.constraint(equalTo: glowContainer.topAnchor),
            playPauseButton.bottomAnchor.constraint(equalTo: glowContainer.bottomAnchor),
            playPauseButton.leadingAnchor.constraint(equalTo: glowContainer.leadingAnchor),
            playPauseButton.trailingAnchor.constraint(equalTo: glowContainer.trailingAnchor)
        ])

        applyGlow()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILImmersiveTransportControlsView, _) in
            view.applyColorAppearanceChange()
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        glowContainer.layer.shadowPath = UIBezierPath(ovalIn: glowContainer.bounds).cgPath
    }

    private func applyColorAppearanceChange() {
        applyGlow()
    }

    /// `--il-med-glow` is a soft drop shadow in light mode and a centered halo in dark mode.
    private func applyGlow() {
        let shadow = traitCollection.userInterfaceStyle == .dark
            ? ILMetrics.shadowMedGoldDark
            : ILMetrics.shadowMedGoldLight
        shadow.apply(to: glowContainer.layer)
        glowContainer.layer.shadowPath = UIBezierPath(ovalIn: glowContainer.bounds).cgPath
    }

    private func updatePlayPauseButton() {
        playPauseButton.isPlaying = isPlaying
        playPauseButton.accessibilityLabel = isPlaying ? pauseAccessibilityLabel : playAccessibilityLabel
    }

    // MARK: - Actions
    @objc private func handleLeadingTap() {
        onLeadingTap?()
    }

    @objc private func handleTrailingTap() {
        onTrailingTap?()
    }
}

// MARK: - Ghost circle button
/// 50pt circle with a thin `medBorder` outline and a small `medInkControl` glyph.
private final class ILImmersiveGhostCircleButton: UIControl {

    enum Glyph {
        /// Hollow 15pt circle, 1.5pt stroke.
        case ring
        /// Filled 13pt rounded square (radius 3).
        case square
    }

    private let glyph: Glyph
    private let glyphLayer = CAShapeLayer()

    init(glyph: Glyph) {
        self.glyph = glyph
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        isAccessibilityElement = true
        accessibilityTraits = .button
        layer.borderWidth = 1
        layer.addSublayer(glyphLayer)
        applyColors()

        let size = ILMetrics.transportSideButtonSize
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: size),
            heightAnchor.constraint(equalToConstant: size)
        ])
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILImmersiveGhostCircleButton, _) in
            view.applyColorAppearanceChange()
        }
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.94, y: 0.94) : .identity
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2
        glyphLayer.frame = bounds

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        switch glyph {
        case .ring:
            let side: CGFloat = 15
            glyphLayer.path = UIBezierPath(ovalIn: CGRect(
                x: center.x - side / 2, y: center.y - side / 2, width: side, height: side
            ).insetBy(dx: 0.75, dy: 0.75)).cgPath
        case .square:
            let side: CGFloat = 13
            glyphLayer.path = UIBezierPath(
                roundedRect: CGRect(x: center.x - side / 2, y: center.y - side / 2, width: side, height: side),
                cornerRadius: 3
            ).cgPath
        }
    }

    private func applyColorAppearanceChange() {
        applyColors()
    }

    private func applyColors() {
        let glyphColor = ILColors.medInkControl.resolvedColor(with: traitCollection).cgColor
        layer.borderColor = ILColors.medBorder.resolvedColor(with: traitCollection).cgColor
        switch glyph {
        case .ring:
            glyphLayer.fillColor = UIColor.clear.cgColor
            glyphLayer.strokeColor = glyphColor
            glyphLayer.lineWidth = 1.5
        case .square:
            glyphLayer.fillColor = glyphColor
            glyphLayer.strokeColor = nil
        }
    }
}
