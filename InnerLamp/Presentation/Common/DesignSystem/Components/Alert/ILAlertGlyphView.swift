//
//  ILAlertGlyphView.swift
//  InnerLamp
//

import UIKit

/// Round tinted badge with a Lora "!" — the error mark shared by every popup in `Components/Alert/`.
public final class ILAlertGlyphView: UIView {

    // MARK: - Properties
    private let diameter: CGFloat
    private let fillColor: UIColor

    // MARK: - UI Elements
    private let glyphLabel = UILabel()

    // MARK: - Initializer
    public init(diameter: CGFloat, font: UIFont, fillColor: UIColor, glyphColor: UIColor) {
        self.diameter = diameter
        self.fillColor = fillColor
        super.init(frame: .zero)
        glyphLabel.font = font
        glyphLabel.textColor = glyphColor
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        isAccessibilityElement = false
        backgroundColor = fillColor
        layer.cornerRadius = diameter / 2

        // Decorative mark, not user-facing copy — the popup title carries the meaning.
        glyphLabel.text = "!"
        glyphLabel.textAlignment = .center
        glyphLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(glyphLabel)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: diameter),
            heightAnchor.constraint(equalToConstant: diameter),
            glyphLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            glyphLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    // MARK: - Animation
    /// Horizontal shake (design `ilshake .5s`): 0 → -5 → 5 → -3 → 3 → 0.
    public func shake(delay: TimeInterval = 0) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.values = [0, -5, 5, -3, 3, 0]
        animation.keyTimes = [0, 0.2, 0.4, 0.6, 0.8, 1]
        animation.duration = 0.5
        animation.beginTime = CACurrentMediaTime() + delay
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(animation, forKey: "shake")
    }
}
