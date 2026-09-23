//
//  ILChevronCircleButton.swift
//  InnerLamp
//

import UIKit

/// Nút tròn 34pt có mũi tên ‹ / › nét mảnh — dùng cho các thanh chuyển trang/tháng (vd. lịch âm).
/// Không mang nội dung riêng của màn nào; chỉ nhận hướng và `onTap`.
public final class ILChevronCircleButton: UIControl {

    public enum Direction {
        case left
        case right
    }

    // MARK: - Properties
    public static let diameter: CGFloat = 34

    public var onTap: (() -> Void)?

    private let direction: Direction
    private let chevronLayer = CAShapeLayer()

    public override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.6 : 1 }
    }

    // MARK: - Initializer
    public init(direction: Direction) {
        self.direction = direction
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    public override func layoutSubviews() {
        super.layoutSubviews()
        chevronLayer.frame = bounds
        chevronLayer.path = makeChevronPath().cgPath
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyColors()
    }

    // MARK: - Setup
    private func setupViews() {
        isAccessibilityElement = true
        accessibilityTraits = .button

        backgroundColor = ILColors.surface
        layer.cornerRadius = Self.diameter / 2
        layer.borderWidth = 1

        chevronLayer.fillColor = nil
        chevronLayer.lineWidth = 1.6
        chevronLayer.lineCap = .round
        chevronLayer.lineJoin = .round
        layer.addSublayer(chevronLayer)

        applyColors()
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: Self.diameter),
            heightAnchor.constraint(equalToConstant: Self.diameter)
        ])
    }

    private func applyColors() {
        layer.borderColor = ILColors.border.resolvedColor(with: traitCollection).cgColor
        chevronLayer.strokeColor = ILColors.ink.resolvedColor(with: traitCollection).cgColor
    }

    private func makeChevronPath() -> UIBezierPath {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let halfWidth: CGFloat = 2.5
        let halfHeight: CGFloat = 4.5
        let sign: CGFloat = direction == .left ? 1 : -1

        let path = UIBezierPath()
        path.move(to: CGPoint(x: center.x + sign * halfWidth, y: center.y - halfHeight))
        path.addLine(to: CGPoint(x: center.x - sign * halfWidth, y: center.y))
        path.addLine(to: CGPoint(x: center.x + sign * halfWidth, y: center.y + halfHeight))
        return path
    }

    @objc private func handleTap() {
        onTap?()
    }
}
