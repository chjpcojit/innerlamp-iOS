//
//  ILRow.swift
//  InnerLamp
//
//  Created by ChjpCoj on 11/9/26.
//

import UIKit

public final class ILRow: UIControl {
    
    public enum Glyph {
        case leaf
        case book
        case circle
        case dot
    }
    
    public enum State {
        case normal
        case selected
        case disabled
    }
    
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
    
    public var trailingText: String = "" {
        didSet {
            trailingLabel.text = trailingText
            trailingLabel.isHidden = trailingText.isEmpty
        }
    }
    
    public var tone: ILColors.Tone = .gold {
        didSet { updateAppearance() }
    }
    
    public var glyph: Glyph = .leaf {
        didSet { updateAppearance() }
    }
    
    public var rowState: State = .normal {
        didSet {
            isEnabled = rowState != .disabled
            updateAppearance()
        }
    }
    
    public var onTap: (() -> Void)?
    
    // MARK: - UI Elements
    private let iconTile = UIView()
    private let glyphView = UIImageView()
    
    private let titleLabel = UILabel()
    private let subLabel = UILabel()
    private let textStack = UIStackView()
    
    private let trailingLabel = UILabel()
    private let contentStack = UIStackView()
    
    // MARK: - Initializer
    public init(
        title: String,
        subtitle: String = "",
        trailingText: String = "",
        tone: ILColors.Tone = .gold,
        glyph: Glyph = .leaf,
        state: State = .normal
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailingText = trailingText
        self.tone = tone
        self.glyph = glyph
        self.rowState = state
        super.init(frame: .zero)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupViews() {
        layer.cornerRadius = ILMetrics.radiusCardSmall
        layer.borderWidth = 1
        
        iconTile.translatesAutoresizingMaskIntoConstraints = false
        iconTile.layer.cornerRadius = ILMetrics.radiusIconTile
        iconTile.clipsToBounds = true
        
        // The icon asset (44×44 viewBox) carries its own padding, so it fills the whole tile.
        glyphView.contentMode = .scaleAspectFit
        glyphView.translatesAutoresizingMaskIntoConstraints = false
        iconTile.addSubview(glyphView)

        NSLayoutConstraint.activate([
            iconTile.widthAnchor.constraint(equalToConstant: ILMetrics.iconTileSize),
            iconTile.heightAnchor.constraint(equalToConstant: ILMetrics.iconTileSize),
            glyphView.leadingAnchor.constraint(equalTo: iconTile.leadingAnchor),
            glyphView.trailingAnchor.constraint(equalTo: iconTile.trailingAnchor),
            glyphView.topAnchor.constraint(equalTo: iconTile.topAnchor),
            glyphView.bottomAnchor.constraint(equalTo: iconTile.bottomAnchor)
        ])
        
        titleLabel.font = ILTypography.rowTitle
        titleLabel.text = title
        
        subLabel.font = ILTypography.subhead
        subLabel.text = subtitle
        subLabel.isHidden = subtitle.isEmpty
        
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subLabel)
        
        trailingLabel.font = ILTypography.subheadMedium
        trailingLabel.text = trailingText
        trailingLabel.isHidden = trailingText.isEmpty
        trailingLabel.setContentHuggingPriority(.required, for: .horizontal)
        
        contentStack.axis = .horizontal
        contentStack.spacing = 14
        contentStack.alignment = .center
        contentStack.isUserInteractionEnabled = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentStack.addArrangedSubview(iconTile)
        contentStack.addArrangedSubview(textStack)
        contentStack.addArrangedSubview(trailingLabel)
        
        addSubview(contentStack)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: ILMetrics.rowHeight),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 13),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -13)
        ])
        
        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)
        
        updateAppearance()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILRow, _) in
            view.applyColorAppearanceChange()
        }
    }
    
    private func updateAppearance() {
        alpha = rowState == .disabled ? 0.5 : 1.0
        
        let isSelected = rowState == .selected
        
        // Card Background & Border — dùng token động (ILColors.surface/border tự đảo
        // theo trait), tint gold translucent trộn với nền phía sau nên tự đúng cả 2 mode.
        if isSelected {
            backgroundColor = ILColors.gold.withAlphaComponent(0.10)
            layer.borderColor = ILColors.goldBorder.cgColor
        } else {
            backgroundColor = ILColors.surface
            layer.borderColor = ILColors.border.cgColor
        }

        // Text Colors
        titleLabel.textColor = ILColors.ink
        subLabel.textColor = ILColors.inkTertiary
        trailingLabel.textColor = ILColors.inkMuted
        
        // Icon Tile & Glyph Appearance
        iconTile.backgroundColor = tone.tintBackground
        glyphView.tintColor = tone.accentColor

        // Same glyph → icon mapping as `IL-Row` in the design (leaf→med, book→book, circle→lamp, dot→talk).
        switch glyph {
        case .leaf: glyphView.image = ILIcons.rowMed
        case .book: glyphView.image = ILIcons.rowBook
        case .circle: glyphView.image = ILIcons.rowLamp
        case .dot: glyphView.image = ILIcons.rowTalk
        }
    }
    
    // `layer.borderColor` là CGColor tĩnh, không tự đảo theo trait — refresh thủ công
    // khi hệ thống đổi light/dark (ink/surface giờ có biến thể dark).
    private func applyColorAppearanceChange() {
        updateAppearance()
    }

    @objc private func handleTouchDown() {
        guard rowState != .disabled else { return }
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = CGAffineTransform(scaleX: 0.99, y: 0.99)
        }
    }
    
    @objc private func handleTouchUp() {
        guard rowState != .disabled else { return }
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = .identity
        }
    }
    
    @objc private func handleTapAction() {
        guard rowState != .disabled else { return }
        onTap?()
    }
}
