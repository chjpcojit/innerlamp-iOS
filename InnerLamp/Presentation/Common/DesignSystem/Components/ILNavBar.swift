//
//  ILNavBar.swift
//  InnerLamp
//
//  Created by ChjpCoj on 24/9/26.
//

import UIKit

/// Dimensions shared between `ILNavBar` and its private sub-buttons.
private enum NavBarLayout {
    /// Round chip + pill action height (design `min-height:38px`).
    static let buttonSize: CGFloat = 38
    /// Horizontal inset of the pill action button (`padding:0 14px`).
    static let pillInset: CGFloat = 14
    /// Gap between the three slots (`gap:10px`).
    static let slotGap: CGFloat = 10
    /// Gap between the right-side buttons (`gap:8px`).
    static let rightGap: CGFloat = 8
}

/// Shared screen header — the modern replacement for the legacy `ILHeaderView`
/// (design handoff `IL-NavBar.dc.html`).
///
/// Layout: a round 38pt back chip on the left, a centered title (+ optional subtitle),
/// and a right side holding an optional pill action button and/or a round ✕ close chip.
/// Both side slots share the same width — the larger of 38pt and the right side's content —
/// so the title stays optically centered even when a screen has a wide right action.
///
/// Usage (wrapped in a sticky band by the screen, see handoff README "Header dùng chung"):
/// ```swift
/// let nav = ILNavBar(title: "settings.header.title".localized, rightActionTitle: "common.save".localized)
/// nav.onBack = { [weak self] in self?.navigationController?.popViewController(animated: true) }
/// nav.onAction = { [weak self] in self?.save() }
/// ```
public final class ILNavBar: UIView {

    // MARK: - Properties
    public var title: String = "" {
        didSet { titleLabel.text = title }
    }

    public var subtitle: String = "" {
        didSet {
            subLabel.text = subtitle
            subLabel.isHidden = subtitle.isEmpty
        }
    }

    /// Label of the pill action button on the right (hidden when empty).
    public var rightActionTitle: String = "" {
        didSet {
            actionButton.title = rightActionTitle
            actionButton.isHidden = rightActionTitle.isEmpty
        }
    }

    public var showBack: Bool = true {
        didSet { backButton.isHidden = !showBack }
    }

    public var showClose: Bool = false {
        didSet { closeButton.isHidden = !showClose }
    }

    /// `true` renders the always-dark palette (hero screens over imagery); `false` uses the
    /// theme-aware tokens that flip with the system appearance.
    public var isDark: Bool = false {
        didSet { updateAppearance() }
    }

    /// `true` drops the chip background and border of the back / close / action buttons so they
    /// sit directly on the imagery below (stretchy hero screens, see `ILStretchyHeaderView`).
    public var usesTransparentButtons: Bool = false {
        didSet { updateAppearance() }
    }

    /// `true` swaps the left chevron for a ✕ glyph (modal-style screens). It still fires `onBack`.
    public var usesCloseGlyphOnLeft: Bool = false {
        didSet {
            backButton.glyph = usesCloseGlyphOnLeft ? .close : .chevronLeft
            backButton.accessibilityLabel = (usesCloseGlyphOnLeft ? "common.close" : "common.back").localized
        }
    }

    public var onBack: (() -> Void)?
    public var onClose: (() -> Void)?
    public var onAction: (() -> Void)?

    // MARK: - UI Elements
    private let backButton = ILNavBarRoundButton(glyph: .chevronLeft)
    private let closeButton = ILNavBarRoundButton(glyph: .close)
    private let actionButton = ILNavBarActionButton()

    private let titleLabel = UILabel()
    private let subLabel = UILabel()
    private let centerStack = UIStackView()

    private let backSlot = UIView()
    private let rightStack = UIStackView()

    // MARK: - Initializer
    public init(
        title: String = "",
        subtitle: String = "",
        rightActionTitle: String = "",
        showBack: Bool = true,
        showClose: Bool = false,
        isDark: Bool = false
    ) {
        self.title = title
        self.subtitle = subtitle
        self.rightActionTitle = rightActionTitle
        self.showBack = showBack
        self.showClose = showClose
        self.isDark = isDark
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        backSlot.translatesAutoresizingMaskIntoConstraints = false

        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.isHidden = !showBack
        backButton.accessibilityLabel = "common.back".localized
        backButton.onTap = { [weak self] in self?.onBack?() }
        backSlot.addSubview(backButton)

        // Center title block — single-line, truncates instead of pushing the side slots.
        titleLabel.font = ILTypography.rowTitle
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.text = title
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        subLabel.font = ILTypography.caption
        subLabel.textAlignment = .center
        subLabel.numberOfLines = 1
        subLabel.lineBreakMode = .byTruncatingTail
        subLabel.text = subtitle
        subLabel.isHidden = subtitle.isEmpty
        subLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        centerStack.axis = .vertical
        centerStack.spacing = 2
        centerStack.alignment = .center
        centerStack.translatesAutoresizingMaskIntoConstraints = false
        centerStack.addArrangedSubview(titleLabel)
        centerStack.addArrangedSubview(subLabel)
        centerStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // Right side: optional pill action + optional round close.
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.title = rightActionTitle
        actionButton.isHidden = rightActionTitle.isEmpty
        actionButton.onTap = { [weak self] in self?.onAction?() }

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.isHidden = !showClose
        closeButton.accessibilityLabel = "common.close".localized
        closeButton.onTap = { [weak self] in self?.onClose?() }

        rightStack.axis = .horizontal
        rightStack.spacing = NavBarLayout.rightGap
        rightStack.alignment = .center
        rightStack.translatesAutoresizingMaskIntoConstraints = false
        rightStack.addArrangedSubview(actionButton)
        rightStack.addArrangedSubview(closeButton)

        addSubview(backSlot)
        addSubview(centerStack)
        addSubview(rightStack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: NavBarLayout.buttonSize),

            // Back slot — mirrors the right stack's width so the title stays optically centered.
            backSlot.leadingAnchor.constraint(equalTo: leadingAnchor),
            backSlot.widthAnchor.constraint(equalTo: rightStack.widthAnchor),
            backSlot.topAnchor.constraint(equalTo: topAnchor),
            backSlot.bottomAnchor.constraint(equalTo: bottomAnchor),

            backButton.leadingAnchor.constraint(equalTo: backSlot.leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: backSlot.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: NavBarLayout.buttonSize),
            backButton.heightAnchor.constraint(equalToConstant: NavBarLayout.buttonSize),

            // Center title block between the back slot and the right stack.
            centerStack.leadingAnchor.constraint(equalTo: backSlot.trailingAnchor, constant: NavBarLayout.slotGap),
            centerStack.trailingAnchor.constraint(equalTo: rightStack.leadingAnchor, constant: -NavBarLayout.slotGap),
            centerStack.centerYAnchor.constraint(equalTo: centerYAnchor),

            // Right stack — min 38pt reserved for centering, hugs its content otherwise.
            rightStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            rightStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            rightStack.heightAnchor.constraint(equalToConstant: NavBarLayout.buttonSize),
            rightStack.widthAnchor.constraint(greaterThanOrEqualToConstant: NavBarLayout.buttonSize),

            actionButton.heightAnchor.constraint(equalToConstant: NavBarLayout.buttonSize),
            closeButton.widthAnchor.constraint(equalToConstant: NavBarLayout.buttonSize),
            closeButton.heightAnchor.constraint(equalToConstant: NavBarLayout.buttonSize)
        ])

        updateAppearance()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILNavBar, _) in
            view.applyColorAppearanceChange()
        }
    }

    // MARK: - Appearance
    private func updateAppearance() {
        // Dark palette is fixed (hero imagery); light palette uses theme-aware tokens.
        let titleColor = isDark ? ILColors.inkOnDark : ILColors.ink
        let dimColor = isDark
            ? ILColors.inkOnDark.withAlphaComponent(0.5)
            : ILColors.ink.withAlphaComponent(0.48)
        let glyphColor = isDark ? ILColors.inkOnDark : ILColors.ink
        let buttonBackground = isDark
            ? ILColors.inkOnDark.withAlphaComponent(0.08)
            : ILColors.surface
        let buttonBorder = isDark
            ? ILColors.inkOnDark.withAlphaComponent(0.18)
            : ILColors.ink.withAlphaComponent(0.10)
        // Light hover approximates the handoff `#F3ECDE`; dark hover matches `rgba(242,235,221,.16)`.
        let buttonHighlight = isDark
            ? ILColors.inkOnDark.withAlphaComponent(0.16)
            : ILColors.ink.withAlphaComponent(0.06)
        let normalBackground = usesTransparentButtons ? UIColor.clear : buttonBackground
        let normalBorder = usesTransparentButtons ? UIColor.clear : buttonBorder

        titleLabel.textColor = titleColor
        subLabel.textColor = dimColor

        backButton.normalBackgroundColor = normalBackground
        backButton.highlightedBackgroundColor = buttonHighlight
        backButton.borderColor = normalBorder
        backButton.glyphColor = glyphColor

        closeButton.normalBackgroundColor = normalBackground
        closeButton.highlightedBackgroundColor = buttonHighlight
        closeButton.borderColor = normalBorder
        closeButton.glyphColor = glyphColor

        actionButton.normalBackgroundColor = normalBackground
        actionButton.highlightedBackgroundColor = buttonHighlight
        actionButton.borderColor = normalBorder
        actionButton.textColor = titleColor
    }

    // `layer.borderColor`/`CAShapeLayer.strokeColor` are static CGColor values and do not flip
    // with the trait — refresh manually when the system appearance changes.
    private func applyColorAppearanceChange() {
        updateAppearance()
    }
}

// MARK: - Round Chip Button (back / close)

/// Round 38pt chip with a chevron or cross glyph, used by `ILNavBar` for the back and close buttons.
private final class ILNavBarRoundButton: UIControl {

    enum Glyph {
        case chevronLeft
        case close
    }

    var normalBackgroundColor: UIColor = .clear { didSet { refresh() } }
    var highlightedBackgroundColor: UIColor = .clear { didSet { refresh() } }
    var borderColor: UIColor = .clear { didSet { refresh() } }
    var glyphColor: UIColor = .clear { didSet { refresh() } }

    var onTap: (() -> Void)?

    var glyph: Glyph {
        didSet { setNeedsLayout() }
    }
    private let glyphLayer = CAShapeLayer()

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? highlightedBackgroundColor : normalBackgroundColor
        }
    }

    init(glyph: Glyph) {
        self.glyph = glyph
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        glyphLayer.frame = bounds
        glyphLayer.path = makeGlyphPath().cgPath
    }

    private func applyColorAppearanceChange() {
        refresh()
    }

    private func setupViews() {
        isAccessibilityElement = true
        accessibilityTraits = .button

        layer.cornerRadius = NavBarLayout.buttonSize / 2
        layer.borderWidth = 1

        glyphLayer.fillColor = nil
        glyphLayer.lineWidth = 1.7
        glyphLayer.lineCap = .round
        glyphLayer.lineJoin = .round
        layer.addSublayer(glyphLayer)

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILNavBarRoundButton, _) in
            view.applyColorAppearanceChange()
        }
    }

    private func refresh() {
        layer.borderColor = borderColor.cgColor
        glyphLayer.strokeColor = glyphColor.cgColor
        backgroundColor = isHighlighted ? highlightedBackgroundColor : normalBackgroundColor
    }

    private func makeGlyphPath() -> UIBezierPath {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let path = UIBezierPath()

        switch glyph {
        case .chevronLeft:
            // Left-pointing chevron "‹" — matches the rotated square of `IL-NavBar.dc.html`.
            let halfWidth: CGFloat = 2.5
            let halfHeight: CGFloat = 4.5
            path.move(to: CGPoint(x: center.x + halfWidth, y: center.y - halfHeight))
            path.addLine(to: CGPoint(x: center.x - halfWidth, y: center.y))
            path.addLine(to: CGPoint(x: center.x + halfWidth, y: center.y + halfHeight))

        case .close:
            // "✕" — two diagonal strokes.
            let reach: CGFloat = 6
            path.move(to: CGPoint(x: center.x - reach, y: center.y - reach))
            path.addLine(to: CGPoint(x: center.x + reach, y: center.y + reach))
            path.move(to: CGPoint(x: center.x + reach, y: center.y - reach))
            path.addLine(to: CGPoint(x: center.x - reach, y: center.y + reach))
        }

        return path
    }

    @objc private func handleTap() {
        onTap?()
    }
}

// MARK: - Pill Action Button

/// Pill action button ("Lưu", "Đăng", "Sửa", "Aa") on the right of `ILNavBar`.
private final class ILNavBarActionButton: UIControl {

    var title: String = "" {
        didSet {
            titleLabel.text = title
            invalidateIntrinsicContentSize()
        }
    }

    var normalBackgroundColor: UIColor = .clear { didSet { refresh() } }
    var highlightedBackgroundColor: UIColor = .clear { didSet { refresh() } }
    var borderColor: UIColor = .clear { didSet { refresh() } }
    var textColor: UIColor = .clear { didSet { titleLabel.textColor = textColor } }

    var onTap: (() -> Void)?

    private let titleLabel = UILabel()

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? highlightedBackgroundColor : normalBackgroundColor
        }
    }

    override var intrinsicContentSize: CGSize {
        let labelSize = titleLabel.intrinsicContentSize
        return CGSize(
            width: labelSize.width + NavBarLayout.pillInset * 2,
            height: NavBarLayout.buttonSize
        )
    }

    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func applyColorAppearanceChange() {
        refresh()
    }

    private func setupViews() {
        isAccessibilityElement = true
        accessibilityTraits = .button

        layer.cornerRadius = NavBarLayout.buttonSize / 2
        layer.borderWidth = 1

        titleLabel.font = ILTypography.bodySmallMedium
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: NavBarLayout.pillInset),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -NavBarLayout.pillInset),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILNavBarActionButton, _) in
            view.applyColorAppearanceChange()
        }
    }

    private func refresh() {
        layer.borderColor = borderColor.cgColor
        backgroundColor = isHighlighted ? highlightedBackgroundColor : normalBackgroundColor
    }

    @objc private func handleTap() {
        onTap?()
    }
}


