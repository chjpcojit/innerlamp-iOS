//
//  ILSettingRow.swift
//  InnerLamp
//
//  Created by ChjpCoj on 11/9/26.
//

import UIKit

public final class ILSettingRow: UIControl {
    
    public enum Kind {
        case chevron
        case `switch`
        case value
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
    
    public var valueText: String = "" {
        didSet {
            valueLabel.text = valueText
            valueLabel.isHidden = valueText.isEmpty
        }
    }
    
    public var kind: Kind = .chevron {
        didSet { updateKindViews() }
    }

    /// Optional leading glyph (a template `ILIcons` image) drawn on a tinted tile; nil = no tile.
    public var icon: UIImage? {
        didSet { updateIcon() }
    }

    public var iconTone: ILColors.Tone = .gold {
        didSet { updateAppearance() }
    }
    
    public var isOn: Bool = false {
        didSet {
            switchControl.isOn = isOn
        }
    }
    
    public var isLast: Bool = false {
        didSet { dividerView.isHidden = isLast }
    }
    
    public var onSwitchToggled: ((Bool) -> Void)?
    public var onTap: (() -> Void)?
    
    // MARK: - UI Elements
    private let iconTile = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subLabel = UILabel()
    private let textStack = UIStackView()
    
    private let valueLabel = UILabel()
    private let chevronLabel = UILabel()
    private let switchControl = UISwitch()
    
    private let rightStack = UIStackView()
    private let contentStack = UIStackView()
    private let dividerView = UIView()
    
    // MARK: - Initializer
    public init(
        title: String,
        subtitle: String = "",
        valueText: String = "",
        kind: Kind = .chevron,
        isOn: Bool = false,
        isLast: Bool = false,
        icon: UIImage? = nil,
        iconTone: ILColors.Tone = .gold
    ) {
        self.title = title
        self.subtitle = subtitle
        self.valueText = valueText
        self.kind = kind
        self.isOn = isOn
        self.isLast = isLast
        self.icon = icon
        self.iconTone = iconTone
        super.init(frame: .zero)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupViews() {
        titleLabel.font = ILTypography.body
        titleLabel.text = title
        
        subLabel.font = ILTypography.label
        subLabel.text = subtitle
        subLabel.isHidden = subtitle.isEmpty
        
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading
        textStack.isUserInteractionEnabled = false
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subLabel)
        
        valueLabel.font = ILTypography.bodySmall
        valueLabel.text = valueText
        valueLabel.isHidden = valueText.isEmpty
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)
        
        chevronLabel.font = ILTypography.beVietnamPro(size: 18, weight: .regular)
        chevronLabel.text = "›"
        chevronLabel.setContentHuggingPriority(.required, for: .horizontal)
        
        switchControl.onTintColor = ILColors.gold
        switchControl.isOn = isOn
        switchControl.isUserInteractionEnabled = false
        switchControl.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
        
        rightStack.axis = .horizontal
        rightStack.spacing = 8
        rightStack.alignment = .center
        rightStack.isUserInteractionEnabled = false
        
        contentStack.axis = .horizontal
        contentStack.spacing = 12
        contentStack.alignment = .center
        contentStack.isUserInteractionEnabled = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        // The 44×44 icon asset carries its own padding, so it fills the whole tile (same as `ILRow`).
        iconTile.layer.cornerRadius = ILMetrics.radiusSettingIconTile
        iconTile.clipsToBounds = true
        iconTile.isUserInteractionEnabled = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconTile.addSubview(iconImageView)
        NSLayoutConstraint.activate([
            iconTile.widthAnchor.constraint(equalToConstant: ILMetrics.settingIconTileSize),
            iconTile.heightAnchor.constraint(equalToConstant: ILMetrics.settingIconTileSize),
            iconImageView.leadingAnchor.constraint(equalTo: iconTile.leadingAnchor),
            iconImageView.trailingAnchor.constraint(equalTo: iconTile.trailingAnchor),
            iconImageView.topAnchor.constraint(equalTo: iconTile.topAnchor),
            iconImageView.bottomAnchor.constraint(equalTo: iconTile.bottomAnchor)
        ])
        contentStack.addArrangedSubview(iconTile)
        contentStack.addArrangedSubview(textStack)
        contentStack.addArrangedSubview(valueLabel)
        contentStack.addArrangedSubview(rightStack)
        
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        dividerView.isUserInteractionEnabled = false
        dividerView.isHidden = isLast
        
        addSubview(contentStack)
        addSubview(dividerView)
        
        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 15),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -15),
            
            dividerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            dividerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            dividerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)
        
        updateKindViews()
        updateIcon()
        updateAppearance()
    }

    private func updateIcon() {
        iconImageView.image = icon
        iconTile.isHidden = icon == nil
    }
    
    private func updateKindViews() {
        rightStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        switch kind {
        case .chevron:
            rightStack.addArrangedSubview(chevronLabel)
        case .switch:
            rightStack.addArrangedSubview(switchControl)
        case .value:
            break
        }
    }
    
    private func updateAppearance() {
        // Token động (ink*) tự đảo theo trait — không cần nhánh isDark thủ công.
        titleLabel.textColor = ILColors.ink
        subLabel.textColor = ILColors.inkTertiary
        valueLabel.textColor = ILColors.inkTertiary
        chevronLabel.textColor = ILColors.inkMuted
        dividerView.backgroundColor = ILColors.border
        iconTile.backgroundColor = iconTone.tintBackground
        iconImageView.tintColor = iconTone.textColor
    }
    
    @objc private func switchValueChanged() {
        isOn = switchControl.isOn
        onSwitchToggled?(isOn)
    }
    
    @objc private func handleTapAction() {
        if kind == .switch {
            switchControl.setOn(!switchControl.isOn, animated: true)
            switchValueChanged()
        } else {
            onTap?()
        }
    }
}
