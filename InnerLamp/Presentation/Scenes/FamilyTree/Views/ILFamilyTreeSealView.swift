//
//  ILFamilyTreeSealView.swift
//  InnerLamp
//

import UIKit

/// Red rounded-square seal with a cream glyph and a thin cream inner ring ("double ring"), slightly
/// rotated like a stamp. Used for the 譜 mark in the header and the 長 mark of the clan head.
final class ILFamilyTreeSealView: UIView {

    private typealias Tree = ILColors.FamilyTree

    // MARK: - Properties
    private let ringLayer = CAShapeLayer()
    private lazy var glyphLabel: UILabel = {
        let label = UILabel()
        label.textColor = Tree.cream
        label.textAlignment = .center
        return label
    }()
    private let ringInset: CGFloat
    private let sealRadius: CGFloat

    // MARK: - Initializer
    /// - Parameters:
    ///   - ringInset: distance from the edge to the inner edge of the 1pt cream ring.
    ///   - rotation: degrees, negative = counter-clockwise.
    init(glyph: String, font: UIFont, size: CGFloat, cornerRadius: CGFloat, ringInset: CGFloat, rotation: CGFloat) {
        self.ringInset = ringInset
        self.sealRadius = cornerRadius
        super.init(frame: CGRect(x: 0, y: 0, width: size, height: size))
        backgroundColor = Tree.seal
        layer.cornerRadius = cornerRadius
        isUserInteractionEnabled = false
        transform = CGAffineTransform(rotationAngle: rotation * .pi / 180)

        ringLayer.fillColor = nil
        ringLayer.strokeColor = Tree.cream.cgColor
        ringLayer.lineWidth = 1
        layer.addSublayer(ringLayer)

        glyphLabel.text = glyph
        glyphLabel.font = font
        addSubview(glyphLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Pins the seal to its square size for Auto Layout hosts (frame-based hosts set the frame instead).
    func pinSize() {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: bounds.width),
            heightAnchor.constraint(equalToConstant: bounds.height)
        ])
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        let center = ringInset + 0.5
        ringLayer.path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: center, dy: center),
            cornerRadius: max(sealRadius - center, 0)
        ).cgPath
        glyphLabel.frame = bounds
    }
}
