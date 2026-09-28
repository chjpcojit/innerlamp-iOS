//
//  ILStatsReminderCardView.swift
//  InnerLamp
//

import UIKit

/// "Giữ chuỗi ngày bằng chuông nhắc" call-to-action at the bottom of Stats: gold-bordered card
/// with a round bell tile, a title + reminder summary and a trailing chevron. The whole card is
/// one tap target.
final class ILStatsReminderCardView: UIControl {

    // MARK: - Constants
    private enum Layout {
        static let horizontalPadding: CGFloat = 18
        static let verticalPadding: CGFloat = 16
        static let iconSize: CGFloat = 38
        static let bellSize = CGSize(width: 12, height: 14)
        static let bellTopRadius: CGFloat = 6
        static let bellBottomRadius: CGFloat = 2
        static let bellLineWidth: CGFloat = 1.5
        static let subtitleTopSpacing: CGFloat = 2
        static let pressedScale: CGFloat = 0.99
    }

    // MARK: - Properties
    var title: String = "" {
        didSet {
            titleLabel.text = title
            updateAccessibility()
        }
    }

    var subtitle: String = "" {
        didSet {
            subtitleLabel.text = subtitle
            updateAccessibility()
        }
    }

    var onTap: (() -> Void)?

    // MARK: - UI Elements
    private let iconTile = UIView()
    private let bellLayer = CAShapeLayer()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let chevronLabel = UILabel()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let origin = CGPoint(
            x: (iconTile.bounds.width - Layout.bellSize.width) / 2,
            y: (iconTile.bounds.height - Layout.bellSize.height) / 2
        )
        bellLayer.frame = CGRect(origin: origin, size: Layout.bellSize)
        bellLayer.path = makeBellPath(in: CGRect(origin: .zero, size: Layout.bellSize)).cgPath
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardRegular
        layer.borderWidth = 1
        layer.borderColor = ILColors.goldRingBorder.cgColor

        iconTile.backgroundColor = ILColors.goldDayTint
        iconTile.layer.cornerRadius = Layout.iconSize / 2
        iconTile.isUserInteractionEnabled = false
        iconTile.translatesAutoresizingMaskIntoConstraints = false

        bellLayer.fillColor = nil
        bellLayer.strokeColor = ILColors.gold.cgColor
        bellLayer.lineWidth = Layout.bellLineWidth
        iconTile.layer.addSublayer(bellLayer)

        titleLabel.font = ILTypography.sectionTitle
        titleLabel.textColor = ILColors.ink
        titleLabel.numberOfLines = 0

        subtitleLabel.font = ILTypography.label
        subtitleLabel.textColor = ILColors.inkTertiary

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = Layout.subtitleTopSpacing
        textStack.isUserInteractionEnabled = false

        chevronLabel.font = ILTypography.chevron
        chevronLabel.textColor = ILColors.inkFaint
        chevronLabel.text = "›"
        chevronLabel.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [iconTile, textStack, chevronLabel])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = ILMetrics.spaceMedium
        row.isUserInteractionEnabled = false
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        NSLayoutConstraint.activate([
            iconTile.widthAnchor.constraint(equalToConstant: Layout.iconSize),
            iconTile.heightAnchor.constraint(equalToConstant: Layout.iconSize),

            row.topAnchor.constraint(equalTo: topAnchor, constant: Layout.verticalPadding),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.verticalPadding),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalPadding),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalPadding)
        ])

        isAccessibilityElement = true
        accessibilityTraits = .button

        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILStatsReminderCardView, _) in
            view.applyColorAppearanceChange()
        }
    }

    /// Bell outline — rounded top (6pt), tight bottom corners (2pt), matching the handoff glyph.
    private func makeBellPath(in rect: CGRect) -> UIBezierPath {
        let inset = rect.insetBy(dx: Layout.bellLineWidth / 2, dy: Layout.bellLineWidth / 2)
        let top = Layout.bellTopRadius - Layout.bellLineWidth / 2
        let bottom = Layout.bellBottomRadius
        let path = UIBezierPath()
        path.move(to: CGPoint(x: inset.minX, y: inset.maxY - bottom))
        path.addLine(to: CGPoint(x: inset.minX, y: inset.minY + top))
        path.addArc(withCenter: CGPoint(x: inset.minX + top, y: inset.minY + top), radius: top, startAngle: .pi, endAngle: .pi * 1.5, clockwise: true)
        path.addLine(to: CGPoint(x: inset.maxX - top, y: inset.minY))
        path.addArc(withCenter: CGPoint(x: inset.maxX - top, y: inset.minY + top), radius: top, startAngle: .pi * 1.5, endAngle: 0, clockwise: true)
        path.addLine(to: CGPoint(x: inset.maxX, y: inset.maxY - bottom))
        path.addArc(withCenter: CGPoint(x: inset.maxX - bottom, y: inset.maxY - bottom), radius: bottom, startAngle: 0, endAngle: .pi * 0.5, clockwise: true)
        path.addLine(to: CGPoint(x: inset.minX + bottom, y: inset.maxY))
        path.addArc(withCenter: CGPoint(x: inset.minX + bottom, y: inset.maxY - bottom), radius: bottom, startAngle: .pi * 0.5, endAngle: .pi, clockwise: true)
        path.close()
        return path
    }

    private func updateAccessibility() {
        accessibilityLabel = title
        accessibilityValue = subtitle
    }

    private func applyColorAppearanceChange() {
        layer.borderColor = ILColors.goldRingBorder.cgColor
        bellLayer.strokeColor = ILColors.gold.cgColor
    }

    // MARK: - Actions
    @objc private func handleTouchDown() {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = CGAffineTransform(scaleX: Layout.pressedScale, y: Layout.pressedScale)
        }
    }

    @objc private func handleTouchUp() {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = .identity
        }
    }

    @objc private func handleTapAction() {
        onTap?()
    }
}
