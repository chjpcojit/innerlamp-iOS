//
//  ILSkeletonLoadingView.swift
//  InnerLamp
//

import UIKit

/// Content-area placeholder shown while a screen loads its content for the first time
/// (design handoff `loading` screen): a pulsing lamp + "Lighting the lamp…" caption, then a
/// title bar, a hero block, two tiles and 4 list rows pulsing with a staggered `ilpulse`.
///
/// Carries no feature content — overlay it on a screen's content area (below its header so
/// Back stays reachable) and drive it from the screen's `ViewState`:
///
/// ```swift
/// case .loading: skeletonView.setLoading(true)
/// case .success, .failure: skeletonView.setLoading(false)
/// ```
public final class ILSkeletonLoadingView: UIView {

    // MARK: - Properties
    public var caption: String {
        get { captionLabel.text ?? "" }
        set {
            captionLabel.text = newValue
            accessibilityLabel = newValue
        }
    }

    public private(set) var isLoading = false

    /// Every layer that pulses, paired with its start delay.
    private var pulsingLayers: [(layer: CALayer, delay: TimeInterval)] = []

    // MARK: - UI Elements
    private let contentStack = UIStackView()
    private let captionRow = UIStackView()
    private let lampRing = UIView()
    private let lampDot = UIView()
    private let captionLabel = UILabel()
    private let titleBar = UIView()
    private let heroBlock = UIView()
    private let tilesRow = UIStackView()
    private let rowsStack = UIStackView()

    // MARK: - Initializer
    /// `caption` defaults to the localized "loading.caption" copy.
    public init(caption: String? = nil) {
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
        self.caption = caption ?? "loading.caption".localized
        isHidden = true

        // CGColor does not follow dark mode on its own.
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.lampRing.layer.borderColor = ILColors.Skeleton.lampRing.resolvedColor(with: self.traitCollection).cgColor
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = ILColors.canvas
        clipsToBounds = true
        isAccessibilityElement = true
        accessibilityTraits = .updatesFrequently

        contentStack.axis = .vertical
        contentStack.alignment = .leading
        contentStack.spacing = ILMetrics.Skeleton.blockSpacing
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        // Caption row
        lampRing.layer.cornerRadius = ILMetrics.Skeleton.lampRingSize / 2
        lampRing.layer.borderWidth = ILMetrics.Skeleton.lampRingBorder
        lampRing.layer.borderColor = ILColors.Skeleton.lampRing.cgColor
        lampDot.backgroundColor = ILColors.goldBright
        lampDot.layer.cornerRadius = ILMetrics.Skeleton.lampDotSize / 2
        lampRing.addSubview(lampDot)

        captionLabel.font = ILTypography.bodySmall
        captionLabel.textColor = ILColors.inkTertiary

        captionRow.axis = .horizontal
        captionRow.alignment = .center
        captionRow.spacing = ILMetrics.Skeleton.captionSpacing
        captionRow.addArrangedSubview(lampRing)
        captionRow.addArrangedSubview(captionLabel)

        // Blocks
        titleBar.backgroundColor = ILColors.Skeleton.bar
        titleBar.layer.cornerRadius = ILMetrics.Skeleton.titleBarRadius

        heroBlock.backgroundColor = ILColors.Skeleton.blockStrong
        heroBlock.layer.cornerRadius = ILMetrics.radiusCardLarge

        tilesRow.axis = .horizontal
        tilesRow.distribution = .fillEqually
        tilesRow.spacing = ILMetrics.rowSpacing
        let tiles = ILMetrics.Skeleton.tilePulseDelays.map { _ -> UIView in
            let tile = UIView()
            tile.backgroundColor = ILColors.Skeleton.lineSoft
            tile.layer.cornerRadius = ILMetrics.radiusCardRegular
            tilesRow.addArrangedSubview(tile)
            return tile
        }

        rowsStack.axis = .vertical
        rowsStack.spacing = ILMetrics.rowSpacing
        let rows = ILMetrics.Skeleton.rowLineWidthRatios.map { ratio -> UIView in
            let row = Self.makePlaceholderRow(lineWidthRatio: ratio)
            rowsStack.addArrangedSubview(row)
            return row
        }

        [captionRow, titleBar, heroBlock, tilesRow, rowsStack].forEach {
            contentStack.addArrangedSubview($0)
        }
        contentStack.setCustomSpacing(ILMetrics.Skeleton.captionBottomSpacing, after: captionRow)

        pulsingLayers = [(lampRing.layer, 0), (titleBar.layer, 0), (heroBlock.layer, ILMetrics.Skeleton.heroPulseDelay)]
            + zip(tiles, ILMetrics.Skeleton.tilePulseDelays).map { ($0.layer, $1) }
            + rows.enumerated().map { ($1.layer, Double($0) * ILMetrics.Skeleton.rowPulseDelayStep) }
    }

    private func setupConstraints() {
        [lampRing, lampDot, titleBar, heroBlock, tilesRow].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: ILMetrics.spaceMedium),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.screenHorizontal),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.screenHorizontal),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),

            lampRing.widthAnchor.constraint(equalToConstant: ILMetrics.Skeleton.lampRingSize),
            lampRing.heightAnchor.constraint(equalToConstant: ILMetrics.Skeleton.lampRingSize),
            lampDot.widthAnchor.constraint(equalToConstant: ILMetrics.Skeleton.lampDotSize),
            lampDot.heightAnchor.constraint(equalToConstant: ILMetrics.Skeleton.lampDotSize),
            lampDot.centerXAnchor.constraint(equalTo: lampRing.centerXAnchor),
            lampDot.centerYAnchor.constraint(equalTo: lampRing.centerYAnchor),

            titleBar.heightAnchor.constraint(equalToConstant: ILMetrics.Skeleton.titleBarHeight),
            heroBlock.heightAnchor.constraint(equalToConstant: ILMetrics.Skeleton.heroHeight),
            tilesRow.heightAnchor.constraint(equalToConstant: ILMetrics.Skeleton.tileHeight)
        ])

        // The stack is `.leading` so the title bar can stay shorter than the other blocks.
        titleBar.widthAnchor.constraint(
            equalTo: contentStack.widthAnchor,
            multiplier: ILMetrics.Skeleton.titleBarWidthRatio
        ).isActive = true
        [captionRow, heroBlock, tilesRow, rowsStack].forEach {
            $0.widthAnchor.constraint(equalTo: contentStack.widthAnchor).isActive = true
        }
    }

    // MARK: - Public
    /// Shows (fading in) and starts pulsing, or stops and hides (fading out).
    public func setLoading(_ loading: Bool, animated: Bool = true) {
        guard loading != isLoading else { return }
        isLoading = loading

        if loading {
            superview?.bringSubviewToFront(self)
            alpha = animated ? 0 : 1
            isHidden = false
            startPulsing()
            if animated {
                UIView.animate(withDuration: 0.2) { self.alpha = 1 }
            }
        } else {
            let finish = { [weak self] in
                guard let self, !self.isLoading else { return }
                self.isHidden = true
                self.stopPulsing()
            }
            if animated {
                UIView.animate(withDuration: 0.2, animations: { self.alpha = 0 }, completion: { _ in finish() })
            } else {
                finish()
            }
        }
    }

    // MARK: - Lifecycle
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        // CAAnimations added before the view has a window are dropped by Core Animation.
        if window != nil, isLoading { startPulsing() }
    }


    // MARK: - Animation
    private func startPulsing() {
        guard window != nil else { return }
        stopPulsing()

        guard !UIAccessibility.isReduceMotionEnabled else {
            pulsingLayers.forEach { $0.layer.opacity = ILMetrics.Skeleton.pulseStaticOpacity }
            return
        }

        let now = CACurrentMediaTime()
        for (layer, delay) in pulsingLayers {
            let pulse = CAKeyframeAnimation(keyPath: "opacity")
            pulse.values = [
                ILMetrics.Skeleton.pulseMinOpacity,
                ILMetrics.Skeleton.pulseMaxOpacity,
                ILMetrics.Skeleton.pulseMinOpacity
            ]
            pulse.keyTimes = [0, 0.5, 1]
            pulse.duration = ILMetrics.Skeleton.pulseDuration
            pulse.repeatCount = .infinity
            pulse.beginTime = now + delay
            pulse.fillMode = .backwards
            pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            // Keeps the pulse alive across app background/foreground.
            pulse.isRemovedOnCompletion = false
            layer.add(pulse, forKey: Self.pulseAnimationKey)
        }
    }

    private func stopPulsing() {
        pulsingLayers.forEach {
            $0.layer.removeAnimation(forKey: Self.pulseAnimationKey)
            $0.layer.opacity = 1
        }
    }

    // MARK: - Factory
    /// One list-row placeholder: icon tile + two text lines on a translucent card.
    private static func makePlaceholderRow(lineWidthRatio: CGFloat) -> UIView {
        let spec = ILMetrics.Skeleton.self

        let card = UIView()
        card.backgroundColor = ILColors.Skeleton.rowBackground
        card.layer.cornerRadius = ILMetrics.radiusCardRegular

        let iconTile = UIView()
        iconTile.backgroundColor = ILColors.Skeleton.bar
        iconTile.layer.cornerRadius = ILMetrics.radiusIconTile

        let textColumn = UIView()

        let line = UIView()
        line.backgroundColor = ILColors.Skeleton.line
        line.layer.cornerRadius = spec.rowLineRadius

        let subLine = UIView()
        subLine.backgroundColor = ILColors.Skeleton.lineSoft
        subLine.layer.cornerRadius = spec.rowLineRadius

        [iconTile, textColumn].forEach { card.addSubview($0) }
        [line, subLine].forEach { textColumn.addSubview($0) }
        [iconTile, textColumn, line, subLine].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            iconTile.topAnchor.constraint(equalTo: card.topAnchor, constant: spec.rowPadding.top),
            iconTile.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -spec.rowPadding.bottom),
            iconTile.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: spec.rowPadding.left),
            iconTile.widthAnchor.constraint(equalToConstant: ILMetrics.iconTileSize),
            iconTile.heightAnchor.constraint(equalToConstant: ILMetrics.iconTileSize),

            textColumn.leadingAnchor.constraint(equalTo: iconTile.trailingAnchor, constant: ILMetrics.spaceMedium),
            textColumn.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -spec.rowPadding.right),
            textColumn.centerYAnchor.constraint(equalTo: iconTile.centerYAnchor),

            line.topAnchor.constraint(equalTo: textColumn.topAnchor),
            line.leadingAnchor.constraint(equalTo: textColumn.leadingAnchor),
            line.heightAnchor.constraint(equalToConstant: spec.rowLineHeight),
            line.widthAnchor.constraint(equalTo: textColumn.widthAnchor, multiplier: lineWidthRatio),

            subLine.topAnchor.constraint(equalTo: line.bottomAnchor, constant: ILMetrics.spaceSmall),
            subLine.leadingAnchor.constraint(equalTo: textColumn.leadingAnchor),
            subLine.bottomAnchor.constraint(equalTo: textColumn.bottomAnchor),
            subLine.heightAnchor.constraint(equalToConstant: spec.rowSubLineHeight),
            subLine.widthAnchor.constraint(equalTo: textColumn.widthAnchor, multiplier: spec.rowSubLineWidthRatio)
        ])
        return card
    }

    private static let pulseAnimationKey = "ilSkeletonPulse"
}
