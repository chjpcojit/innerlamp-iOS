//
//  ILBellPadView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import UIKit

/// The center strike pad of the "Chuông mõ" screen: a gold halo (radial gradient), a thin ring, and
/// a large circular pad showing a tag ("MÕ" / "CHUÔNG"), the running count, and a hint. It exposes
/// `flashMo()` / `flashBell()` so the `ViewController` can replay the design's strike feedback.
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

    var onTap: (() -> Void)?

    // MARK: - UI Elements
    private let haloView = UIView()
    private let haloGradient = CAGradientLayer()
    private let ringView = UIView()
    private let padView = UIView()
    private let tagLabel = UILabel()
    private let numberLabel = UILabel()
    private let hintLabel = UILabel()

    // MARK: - Layout constants (design handoff)
    private static let outerSize: CGFloat = 236
    private static let ringInset: CGFloat = 6
    private static let padSize: CGFloat = 188
    private static let baseHaloOpacity: Float = 0.18

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
        // Halo — radial gold glow that fades to transparent.
        haloGradient.type = .radial
        haloGradient.colors = [ILColors.medGoldHalo.cgColor, ILColors.medGoldHalo.withAlphaComponent(0).cgColor]
        haloGradient.startPoint = CGPoint(x: 0.5, y: 0.5)
        haloGradient.endPoint = CGPoint(x: 1, y: 1)
        haloGradient.locations = [0, 0.68]
        haloGradient.opacity = Self.baseHaloOpacity
        haloView.layer.addSublayer(haloGradient)
        haloView.isUserInteractionEnabled = false
        haloView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(haloView)

        // Thin outer ring.
        ringView.backgroundColor = .clear
        ringView.layer.borderWidth = 1
        ringView.layer.borderColor = ILColors.medTrack.cgColor
        ringView.isUserInteractionEnabled = false
        ringView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(ringView)

        // The pad itself.
        padView.backgroundColor = ILColors.medCard
        padView.layer.borderWidth = 1.5
        padView.layer.borderColor = ILColors.medBorder.cgColor
        padView.isUserInteractionEnabled = false
        padView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(padView)

        tagLabel.font = ILTypography.eyebrowSmall
        tagLabel.textAlignment = .center
        tagLabel.translatesAutoresizingMaskIntoConstraints = false

        numberLabel.font = ILTypography.bellPadNumber
        numberLabel.textColor = ILColors.medInk
        numberLabel.textAlignment = .center
        numberLabel.translatesAutoresizingMaskIntoConstraints = false

        hintLabel.font = ILTypography.subhead
        hintLabel.textColor = ILColors.medInkTertiary
        hintLabel.textAlignment = .center
        hintLabel.translatesAutoresizingMaskIntoConstraints = false

        let padStack = UIStackView(arrangedSubviews: [tagLabel, numberLabel, hintLabel])
        padStack.axis = .vertical
        padStack.alignment = .center
        padStack.spacing = 8
        padStack.isUserInteractionEnabled = false
        padStack.translatesAutoresizingMaskIntoConstraints = false
        padView.addSubview(padStack)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: Self.outerSize),
            heightAnchor.constraint(equalToConstant: Self.outerSize),

            haloView.topAnchor.constraint(equalTo: topAnchor),
            haloView.bottomAnchor.constraint(equalTo: bottomAnchor),
            haloView.leadingAnchor.constraint(equalTo: leadingAnchor),
            haloView.trailingAnchor.constraint(equalTo: trailingAnchor),

            ringView.topAnchor.constraint(equalTo: topAnchor, constant: Self.ringInset),
            ringView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Self.ringInset),
            ringView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.ringInset),
            ringView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.ringInset),

            padView.centerXAnchor.constraint(equalTo: centerXAnchor),
            padView.centerYAnchor.constraint(equalTo: centerYAnchor),
            padView.widthAnchor.constraint(equalToConstant: Self.padSize),
            padView.heightAnchor.constraint(equalToConstant: Self.padSize),

            padStack.centerXAnchor.constraint(equalTo: padView.centerXAnchor),
            padStack.centerYAnchor.constraint(equalTo: padView.centerYAnchor)
        ])

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        isAccessibilityElement = true
        accessibilityTraits = .button
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILBellPadView, _) in
            view.applyColorAppearanceChange()
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        haloGradient.frame = haloView.bounds
        ringView.layer.cornerRadius = ringView.bounds.width / 2
        padView.layer.cornerRadius = padView.bounds.width / 2
    }

    private func applyColorAppearanceChange() {
        refreshLayerColors()
    }

    private func refreshLayerColors() {
        ringView.layer.borderColor = ILColors.medTrack.cgColor
        padView.layer.borderColor = ILColors.medBorder.cgColor
        haloGradient.colors = [ILColors.medGoldHalo.cgColor, ILColors.medGoldHalo.withAlphaComponent(0).cgColor]
    }

    // MARK: - Strike feedback
    /// Wooden-fish strike: pad dips to 95% and the border flashes gold.
    func flashMo() {
        padView.layer.borderColor = ILColors.medGoldStrikeBorder.cgColor
        animatePadScale(to: 0.95, then: {
            self.padView.layer.borderColor = ILColors.medBorder.cgColor
        })
    }

    /// Bell strike: halo swells to full opacity + 108% while the border flashes gold.
    func flashBell() {
        padView.layer.borderColor = ILColors.medGoldStrikeBorder.cgColor
        let halo = haloGradient
        let up = CABasicAnimation(keyPath: "opacity")
        up.fromValue = Self.baseHaloOpacity
        up.toValue = Float(1.0)
        up.duration = 0.12
        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 1.0
        scale.toValue = 1.08
        scale.duration = 0.42
        halo.add(up, forKey: "opacity")
        halo.add(scale, forKey: "transform.scale")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            self.padView.layer.borderColor = ILColors.medBorder.cgColor
        }
    }

    private func animatePadScale(to scale: CGFloat, then completion: @escaping () -> Void) {
        UIView.animate(
            withDuration: 0.06,
            delay: 0,
            options: [.curveEaseOut, .allowUserInteraction],
            animations: { self.padView.transform = CGAffineTransform(scaleX: scale, y: scale) },
            completion: { _ in
                UIView.animate(
                    withDuration: 0.06,
                    delay: 0,
                    options: [.curveEaseOut, .allowUserInteraction],
                    animations: { self.padView.transform = .identity },
                    completion: { _ in completion() }
                )
            }
        )
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
