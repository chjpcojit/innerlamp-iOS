//
//  ILPlayPauseButton.swift
//  InnerLamp
//

import UIKit

/// Nút tròn play/pause dùng chung — nền `ink`, glyph vàng (2 vạch khi đang phát, tam giác khi
/// tạm dừng), khớp nút phát trên thanh phát màn Tụng kinh (`isReader`) và trình phát (`player`/
/// `talk`) trong design handoff. Chỉ phụ thuộc `isPlaying` và `size` nên đặt ở DesignSystem.
public final class ILPlayPauseButton: UIControl {

    // MARK: - Properties
    /// `true` hiển thị glyph "tạm dừng" (2 vạch), `false` hiển thị glyph "phát" (tam giác).
    public var isPlaying: Bool = false {
        // The glyph is a `CAShapeLayer` rebuilt in `layoutSubviews`, so a redraw alone
        // (`setNeedsDisplay`) would leave the old play/pause shape on screen.
        didSet { setNeedsLayout() }
    }

    public var onTap: (() -> Void)?

    // MARK: - UI Elements
    private let glyphLayer = CAShapeLayer()
    private let diameter: CGFloat
    private let glyphColor: UIColor
    private let fillColor: UIColor
    private let glyphScale: CGFloat
    private let playGlyphSize: CGSize
    private let playGlyphOffsetX: CGFloat

    // MARK: - Initializer
    /// - Parameters:
    ///   - fillColor: Button background — `ink` by default; immersive screens pass `medGold`.
    ///   - glyphScale: Multiplier on the base glyph (4×16 pause bars) — e.g. `1.5` for the 78px
    ///     gold button of the meditation session (5×24 bars in the design).
    ///   - playGlyphSize: Size of the "play" triangle before `glyphScale` (11×15 by default).
    ///   - playGlyphOffsetX: Horizontal shift of the triangle from the circle's center, for
    ///     designs that nudge it optically (e.g. `margin-left:3px`).
    public init(
        diameter: CGFloat = 46,
        glyphColor: UIColor = ILColors.goldLight,
        fillColor: UIColor = ILColors.ink,
        glyphScale: CGFloat = 1,
        playGlyphSize: CGSize = CGSize(width: 11, height: 15),
        playGlyphOffsetX: CGFloat = 0
    ) {
        self.diameter = diameter
        self.glyphColor = glyphColor
        self.fillColor = fillColor
        self.glyphScale = glyphScale
        self.playGlyphSize = playGlyphSize
        self.playGlyphOffsetX = playGlyphOffsetX
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = fillColor
        layer.cornerRadius = diameter / 2
        clipsToBounds = true

        isAccessibilityElement = true
        accessibilityTraits = .button

        glyphLayer.fillColor = glyphColor.cgColor
        layer.addSublayer(glyphLayer)

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: diameter),
            heightAnchor.constraint(equalToConstant: diameter)
        ])
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILPlayPauseButton, _) in
            view.applyColorAppearanceChange()
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        glyphLayer.frame = bounds
        glyphLayer.path = makeGlyphPath().cgPath
    }

    // `CAShapeLayer.fillColor` là CGColor tĩnh, không tự đảo theo trait — refresh thủ công khi
    // hệ thống đổi light/dark.
    private func applyColorAppearanceChange() {
        glyphLayer.fillColor = glyphColor.cgColor
    }

    private func makeGlyphPath() -> UIBezierPath {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let path = UIBezierPath()

        if isPlaying {
            // Hai vạch dọc "tạm dừng" (khớp 2 thanh 4×16px trong design handoff).
            let barWidth: CGFloat = 4 * glyphScale
            let barHeight: CGFloat = 16 * glyphScale
            let gap: CGFloat = 4 * glyphScale
            let halfHeight = barHeight / 2
            let y = center.y - halfHeight
            path.append(UIBezierPath(
                roundedRect: CGRect(x: center.x - gap / 2 - barWidth, y: y, width: barWidth, height: barHeight),
                cornerRadius: ILMetrics.radiusGlyph
            ))
            path.append(UIBezierPath(
                roundedRect: CGRect(x: center.x + gap / 2, y: y, width: barWidth, height: barHeight),
                cornerRadius: ILMetrics.radiusGlyph
            ))
        } else {
            // Tam giác "phát" hướng phải.
            let halfWidth = playGlyphSize.width / 2 * glyphScale
            let halfHeight = playGlyphSize.height / 2 * glyphScale
            let centerX = center.x + playGlyphOffsetX
            path.move(to: CGPoint(x: centerX - halfWidth, y: center.y - halfHeight))
            path.addLine(to: CGPoint(x: centerX + halfWidth, y: center.y))
            path.addLine(to: CGPoint(x: centerX - halfWidth, y: center.y + halfHeight))
            path.close()
        }

        return path
    }

    @objc private func handleTap() {
        onTap?()
    }
}
