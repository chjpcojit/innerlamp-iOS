//
//  ILStatHeroCardView.swift
//  InnerLamp
//

import UIKit

/// Theme-aware featured stat card (handoff `--il-feat-*`): uppercase accent eyebrow, a large number
/// with a unit beside it, an optional note and an optional gold progress bar, plus a radial glow in
/// the top-right corner. Takes plain strings only, so any screen can reuse it
/// (e.g. "CHUỖI NGÀY TINH TẤN · 42 ngày liên tục" on Stats).
public final class ILStatHeroCardView: UIView {

    // MARK: - Constants
    private enum Layout {
        static let horizontalPadding: CGFloat = 22
        static let verticalPadding: CGFloat = 24
        static let valueTopSpacing: CGFloat = 12
        static let valueUnitSpacing: CGFloat = 8
        static let noteTopSpacing: CGFloat = 10
        static let progressTopSpacing: CGFloat = 14
        static let progressHeight: CGFloat = 5
        static let glowSize: CGFloat = 210
        static let glowOffset: CGFloat = 60
        static let eyebrowLetterSpacingEm: CGFloat = 0.16
        static let noteLineHeight: CGFloat = 1.6
    }

    // MARK: - Properties
    public var eyebrow: String = "" {
        didSet { renderEyebrow() }
    }

    public var valueText: String = "" {
        didSet { valueLabel.text = valueText }
    }

    public var unitText: String = "" {
        didSet { unitLabel.text = unitText }
    }

    /// Hidden when empty.
    public var note: String = "" {
        didSet { renderNote() }
    }

    /// 0...1, nil hides the progress bar.
    public var progress: Double? {
        didSet { renderProgress() }
    }

    // MARK: - UI Elements
    private let gradientLayer = CAGradientLayer()
    private let glowLayer = CAGradientLayer()
    private let eyebrowLabel = UILabel()
    private let valueLabel = UILabel()
    private let unitLabel = UILabel()
    private let noteLabel = UILabel()
    private let trackView = UIView()
    private let fillView = ILStatHeroGradientView()
    private let contentStack = UIStackView()
    private var fillWidthConstraint: NSLayoutConstraint?

    // MARK: - Initializer
    public init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        glowLayer.frame = CGRect(
            x: bounds.width - Layout.glowSize + Layout.glowOffset,
            y: -Layout.glowOffset,
            width: Layout.glowSize,
            height: Layout.glowSize
        )
        glowLayer.cornerRadius = Layout.glowSize / 2
    }

    // MARK: - Setup
    private func setupViews() {
        layer.cornerRadius = ILMetrics.radiusCardLarge
        layer.borderWidth = 1
        clipsToBounds = true

        gradientLayer.startPoint = CGPoint(x: 0.1, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.9, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)

        glowLayer.type = .radial
        glowLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        glowLayer.endPoint = CGPoint(x: 1, y: 1)
        glowLayer.locations = [0, 0.66]
        layer.insertSublayer(glowLayer, above: gradientLayer)

        valueLabel.font = ILTypography.statHero
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)
        unitLabel.font = ILTypography.bodyCompact

        let valueRow = UIStackView(arrangedSubviews: [valueLabel, unitLabel])
        valueRow.axis = .horizontal
        valueRow.alignment = .lastBaseline
        valueRow.spacing = Layout.valueUnitSpacing

        noteLabel.numberOfLines = 0

        trackView.layer.cornerRadius = Layout.progressHeight / 2
        trackView.clipsToBounds = true
        fillView.translatesAutoresizingMaskIntoConstraints = false
        fillView.layer.cornerRadius = Layout.progressHeight / 2
        fillView.clipsToBounds = true
        fillView.gradientLayer.colors = [ILColors.goldBright.cgColor, ILColors.goldOnDark.cgColor]
        fillView.gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        fillView.gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        trackView.addSubview(fillView)

        NSLayoutConstraint.activate([
            trackView.heightAnchor.constraint(equalToConstant: Layout.progressHeight),
            fillView.leadingAnchor.constraint(equalTo: trackView.leadingAnchor),
            fillView.topAnchor.constraint(equalTo: trackView.topAnchor),
            fillView.bottomAnchor.constraint(equalTo: trackView.bottomAnchor)
        ])

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        [eyebrowLabel, valueRow, noteLabel, trackView].forEach { contentStack.addArrangedSubview($0) }
        contentStack.setCustomSpacing(Layout.valueTopSpacing, after: eyebrowLabel)
        contentStack.setCustomSpacing(Layout.noteTopSpacing, after: valueRow)
        contentStack.setCustomSpacing(Layout.progressTopSpacing, after: noteLabel)
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: Layout.verticalPadding),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.verticalPadding),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalPadding),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalPadding)
        ])

        renderEyebrow()
        renderNote()
        renderProgress()
        updateAppearance()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILStatHeroCardView, _) in
            view.applyColorAppearanceChange()
        }
    }

    // MARK: - Render
    private func renderEyebrow() {
        eyebrowLabel.attributedText = ILTypography.makeAttributedString(
            text: eyebrow.uppercased(),
            font: ILTypography.eyebrowSmall,
            color: ILColors.featAccent,
            letterSpacingEm: Layout.eyebrowLetterSpacingEm
        )
    }

    private func renderNote() {
        noteLabel.attributedText = ILTypography.makeParagraph(
            text: note,
            font: ILTypography.bodySmall,
            color: ILColors.featSub,
            cssLineHeight: Layout.noteLineHeight
        )
        noteLabel.isHidden = note.isEmpty
    }

    private func renderProgress() {
        trackView.isHidden = progress == nil
        fillWidthConstraint?.isActive = false
        let fraction = CGFloat(min(max(progress ?? 0, 0), 1))
        fillWidthConstraint = fillView.widthAnchor.constraint(equalTo: trackView.widthAnchor, multiplier: fraction)
        fillWidthConstraint?.isActive = true
    }

    private func updateAppearance() {
        gradientLayer.colors = [ILColors.featBackgroundStart.cgColor, ILColors.featBackgroundEnd.cgColor]
        glowLayer.colors = [ILColors.featGlow.cgColor, ILColors.featGlowClear.cgColor]
        layer.borderColor = ILColors.featBorder.cgColor
        valueLabel.textColor = ILColors.ink
        unitLabel.textColor = ILColors.featSub
        trackView.backgroundColor = ILColors.featTrack
        renderEyebrow()
        renderNote()
    }

    // CGColor-backed layers do not flip with the trait — refresh on appearance change.
    private func applyColorAppearanceChange() {
        updateAppearance()
    }
}

// MARK: - Gradient Fill

/// Plain view backed by a `CAGradientLayer`, so the gradient always tracks the view's bounds.
private final class ILStatHeroGradientView: UIView {

    override class var layerClass: AnyClass { CAGradientLayer.self }

    var gradientLayer: CAGradientLayer {
        // `layerClass` guarantees the backing layer type.
        layer as? CAGradientLayer ?? CAGradientLayer()
    }
}
