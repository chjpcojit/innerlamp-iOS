//
//  ILLampStageView.swift
//  InnerLamp
//

import UIKit

/// Hero stage of the "Thắp đèn" screen: a warm card with the headline and the lamp. After the
/// lamp is lit the card grows, the lamp moves to the centre and scales up, and the headline is
/// replaced by "Đèn đã được thắp" + a caption (design handoff `offer`).
///
/// State changes are applied without animation here; the owner wraps `setLit(_:completion:)` in a
/// `UIView.animate` block together with `layoutIfNeeded()` so the height, position, scale and
/// fades animate in one transaction.
final class ILLampStageView: UIView {

    // MARK: - UI Elements
    private let gradientLayer = CAGradientLayer()
    private let warmLayer = CAGradientLayer()

    private lazy var formStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 10
        return stack
    }()

    private lazy var kickerLabel: UILabel = {
        let label = UILabel()
        return label
    }()

    private lazy var headlineLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.scriptureTitle
        label.textColor = ILColors.heroInk
        label.numberOfLines = 0
        label.text = "lightLamp.stage.headline".localized
        return label
    }()

    private lazy var countLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.taglineItalic
        label.textColor = ILColors.heroSub
        label.numberOfLines = 0
        return label
    }()

    private lazy var doneTitleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.displayMedium
        label.textColor = ILColors.heroInk
        label.textAlignment = .center
        label.text = "lightLamp.stage.done".localized
        label.alpha = 0
        return label
    }()

    private lazy var captionLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.bodySmall
        label.textColor = ILColors.heroSub
        label.textAlignment = .center
        label.alpha = 0
        return label
    }()

    private let artView: ILLampArtView

    private var heightConstraint: NSLayoutConstraint?
    private var artTopConstraint: NSLayoutConstraint?
    private var artTrailingConstraint: NSLayoutConstraint?
    private var artCenterConstraint: NSLayoutConstraint?

    // MARK: - Initializer
    init(kind: ILLampKind) {
        artView = ILLampArtView(kind: kind, isLit: false)
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public
    func configure(kind: ILLampKind, kicker: String, countLine: String) {
        artView.kind = kind
        kickerLabel.attributedText = ILTypography.makeEyebrow(text: kicker, color: ILColors.heroAccent)
        countLabel.text = countLine
    }

    /// Switches between the unlit form layout and the lit completion layout. Not animated itself.
    func setLit(_ lit: Bool, caption: String?) {
        let metrics = ILMetrics.Lamp.self
        heightConstraint?.constant = lit ? metrics.stageHeightLit : metrics.stageHeightForm
        artTopConstraint?.constant = lit ? metrics.litArtTop : metrics.heroArtTop
        artTrailingConstraint?.isActive = !lit
        artCenterConstraint?.isActive = lit

        let scale = lit ? metrics.litArtScale : 1
        let artHeight = metrics.heroArtSize * metrics.artHeightRatio
        // Scale about the top edge (design `transform-origin: 50% 0`): compensate the centre-based
        // UIKit scale with a downward shift of half the growth.
        artView.transform = CGAffineTransform(scaleX: scale, y: scale)
            .concatenating(CGAffineTransform(translationX: 0, y: (scale - 1) * artHeight / 2))

        formStack.alpha = lit ? 0 : 1
        doneTitleLabel.alpha = lit ? 1 : 0
        captionLabel.alpha = lit ? 1 : 0
        if let caption { captionLabel.text = caption }
    }

    /// Ignites / extinguishes the artwork flame and the warm wash (independent, slower fade).
    func setIgnited(_ ignited: Bool, animated: Bool) {
        artView.setLit(ignited, animated: animated)
        let apply = { self.warmLayer.opacity = ignited ? 1 : 0 }
        guard animated else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            apply()
            CATransaction.commit()
            return
        }
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = warmLayer.presentation()?.opacity ?? warmLayer.opacity
        fade.toValue = ignited ? 1 : 0
        fade.duration = 2
        warmLayer.add(fade, forKey: "warm")
        apply()
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        warmLayer.frame = bounds
    }

    // MARK: - Setup
    private func setupViews() {
        layer.cornerRadius = ILMetrics.radiusCardLarge
        layer.borderWidth = 1
        layer.borderColor = ILColors.featBorder.cgColor
        clipsToBounds = true

        gradientLayer.colors = [ILColors.featBackgroundStart.cgColor, ILColors.featBackgroundEnd.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.2, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.8, y: 1)
        layer.addSublayer(gradientLayer)

        warmLayer.type = .radial
        warmLayer.colors = [
            ILColors.Lamp.stageWarmCore.cgColor,
            ILColors.Lamp.stageWarmMid.cgColor,
            ILColors.goldGlowClear.cgColor
        ]
        warmLayer.locations = [0, 0.55, 0.8]
        warmLayer.startPoint = CGPoint(x: 0.5, y: 0.45)
        warmLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        warmLayer.opacity = 0
        layer.addSublayer(warmLayer)

        [kickerLabel, headlineLabel, countLabel].forEach { formStack.addArrangedSubview($0) }

        [formStack, doneTitleLabel, captionLabel, artView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
    }

    private func setupConstraints() {
        let metrics = ILMetrics.Lamp.self
        let height = heightAnchor.constraint(equalToConstant: metrics.stageHeightForm)
        let top = artView.topAnchor.constraint(equalTo: topAnchor, constant: metrics.heroArtTop)
        let trailing = artView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -metrics.heroArtTrailing)
        let center = artView.centerXAnchor.constraint(equalTo: centerXAnchor)
        heightConstraint = height
        artTopConstraint = top
        artTrailingConstraint = trailing
        artCenterConstraint = center

        NSLayoutConstraint.activate([
            height, top, trailing,
            artView.widthAnchor.constraint(equalToConstant: metrics.heroArtSize),
            artView.heightAnchor.constraint(equalToConstant: metrics.heroArtSize * metrics.artHeightRatio),

            formStack.topAnchor.constraint(equalTo: topAnchor, constant: metrics.stageTextTop),
            formStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.screenHorizontal),
            formStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -metrics.stageTextTrailing),

            doneTitleLabel.topAnchor.constraint(equalTo: topAnchor, constant: metrics.stageTextTop),
            doneTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.screenHorizontal),
            doneTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.screenHorizontal),

            captionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.screenHorizontal),
            captionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.screenHorizontal),
            captionLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18)
        ])
    }
}
