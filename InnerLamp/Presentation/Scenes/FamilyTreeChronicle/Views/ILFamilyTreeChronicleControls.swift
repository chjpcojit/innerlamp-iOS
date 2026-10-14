//
//  ILFamilyTreeChronicleControls.swift
//  InnerLamp
//

import UIKit

/// Tappable container: dims while pressed and calls `onTap`.
final class ILFamilyTreeChronicleTapControl: UIControl {

    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        accessibilityTraits = .button
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.6 : 1 }
    }

    @objc private func handleTap() { onTap?() }
}

/// Small right-pointing chevron at the end of a tappable row.
final class ILFamilyTreeChronicleChevronView: UIView {

    private enum Layout {
        static let size: CGFloat = 10
        static let lineWidth: CGFloat = 1.4
    }

    init() {
        super.init(frame: .zero)
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = false
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: Layout.size),
            heightAnchor.constraint(equalToConstant: Layout.size)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 3, y: 1))
        path.addLine(to: CGPoint(x: 7, y: 5))
        path.addLine(to: CGPoint(x: 3, y: 9))
        path.lineWidth = Layout.lineWidth
        path.lineCapStyle = .round
        ILColors.FamilyTree.inkMuted.setStroke()
        path.stroke()
    }
}

/// 44pt tap target with a small red ✕ — deletes a milestone row.
final class ILFamilyTreeChronicleDeleteButton: UIControl {

    private enum Layout {
        static let size: CGFloat = 44
        static let glyph: CGFloat = 8
        static let lineWidth: CGFloat = 2
    }

    var onTap: (() -> Void)?

    init() {
        super.init(frame: .zero)
        backgroundColor = .clear
        isOpaque = false
        accessibilityTraits = .button
        accessibilityLabel = "familyTreeChronicle.milestone.delete".localized
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: Layout.size),
            heightAnchor.constraint(equalToConstant: Layout.size)
        ])
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.6 : 1 }
    }

    override func draw(_ rect: CGRect) {
        let c = CGPoint(x: bounds.midX, y: bounds.midY)
        let path = UIBezierPath()
        path.move(to: CGPoint(x: c.x - Layout.glyph, y: c.y - Layout.glyph))
        path.addLine(to: CGPoint(x: c.x + Layout.glyph, y: c.y + Layout.glyph))
        path.move(to: CGPoint(x: c.x + Layout.glyph, y: c.y - Layout.glyph))
        path.addLine(to: CGPoint(x: c.x - Layout.glyph, y: c.y + Layout.glyph))
        path.lineWidth = Layout.lineWidth
        path.lineCapStyle = .round
        ILColors.danger.setStroke()
        path.stroke()
    }

    @objc private func handleTap() { onTap?() }
}

/// Pill button: filled forest with cream text, or outlined forest.
final class ILFamilyTreeChroniclePillButton: UIControl {

    enum Style {
        case filled
        case outlined
        /// The dashed "+ Thêm mốc" button.
        case dashed
    }

    private enum Layout {
        static let verticalPadding: CGFloat = 4
        static let dashPattern: [NSNumber] = [4, 3]
        static let borderWidth: CGFloat = 1
    }

    var onTap: (() -> Void)?

    private lazy var titleLabel: UILabel = {
        let v = UILabel()
        v.textAlignment = .center
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let style: Style
    private let dashLayer = CAShapeLayer()

    init(title: String, style: Style, font: UIFont, height: CGFloat) {
        self.style = style
        super.init(frame: .zero)
        accessibilityTraits = .button
        accessibilityLabel = title
        titleLabel.text = title
        titleLabel.font = font

        switch style {
        case .filled:
            layer.cornerRadius = height / 2
            backgroundColor = ILColors.FamilyTree.forest
            titleLabel.textColor = ILColors.FamilyTree.cream
        case .outlined:
            layer.cornerRadius = height / 2
            layer.borderWidth = Layout.borderWidth
            layer.borderColor = ILColors.FamilyTree.outlineButtonBorder.cgColor
            titleLabel.textColor = ILColors.FamilyTree.forest
        case .dashed:
            layer.cornerRadius = ILMetrics.FamilyTree.sheetCardRadius
            dashLayer.fillColor = nil
            dashLayer.strokeColor = ILColors.FamilyTree.outlineButtonBorder.cgColor
            dashLayer.lineDashPattern = Layout.dashPattern
            dashLayer.lineWidth = Layout.borderWidth
            layer.addSublayer(dashLayer)
            titleLabel.textColor = ILColors.FamilyTree.forest
        }

        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: height),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: Layout.verticalPadding),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.verticalPadding),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.spaceMedium),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.spaceMedium)
        ])
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILFamilyTreeChroniclePillButton, _) in
            view.applyColors()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.7 : 1 }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if style == .dashed {
            dashLayer.path = UIBezierPath(
                roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), cornerRadius: ILMetrics.FamilyTree.sheetCardRadius
            ).cgPath
        }
    }

    private func applyColors() {
        switch style {
        case .filled: break
        case .outlined: layer.borderColor = ILColors.FamilyTree.outlineButtonBorder.cgColor
        case .dashed: dashLayer.strokeColor = ILColors.FamilyTree.outlineButtonBorder.cgColor
        }
    }

    @objc private func handleTap() { onTap?() }
}
