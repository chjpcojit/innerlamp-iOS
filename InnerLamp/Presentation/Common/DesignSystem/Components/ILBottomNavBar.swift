//
//  ILBottomNavBar.swift
//  InnerLamp
//
//  Created by ChjpCoj on 11/9/26.
//

import UIKit

public final class ILBottomNavBar: UIView {
    
    public enum Tab: String, CaseIterable {
        case home = "home"
        case lib = "lib"
        case lamp = "lamp"
        case sangha = "sangha"
        case me = "me"
        
        public var title: String {
            switch self {
            case .home: return "Trang chủ"
            case .lib: return "Thư viện"
            case .lamp: return ""
            case .sangha: return "Chùa"
            case .me: return "Tôi"
            }
        }

        /// Solid template icon of the tab (`IL-BottomNav.dc.html`). `.lamp` has none — it is the
        /// separate center lamp button.
        var icon: UIImage? {
            switch self {
            case .home: return ILIcons.tabHome
            case .lib: return ILIcons.tabLib
            case .sangha: return ILIcons.tabSangha
            case .me: return ILIcons.tabMe
            case .lamp: return nil
            }
        }
    }
    
    // MARK: - Properties
    public var activeTab: Tab = .home {
        didSet { updateActiveState() }
    }
    
    /// Reads the system trait directly — never cached, so it cannot drift when the user switches
    /// theme while the app runs (`registerForTraitChanges` triggers a refresh).
    private var isDark: Bool { traitCollection.userInterfaceStyle == .dark }

    public var onTabSelected: ((Tab) -> Void)?
    
    // MARK: - UI Elements
    private let gradientLayer = CAGradientLayer()
    private let topLine = UIView()
    private let contentStack = UIStackView()
    
    private var tabButtons: [Tab: UIControl] = [:]
    private var iconViews: [Tab: UIImageView] = [:]
    private var labelViews: [Tab: UILabel] = [:]
    private let lampButton = ILLampButton()
    
    // MARK: - Initializer
    public init(activeTab: Tab = .home) {
        self.activeTab = activeTab
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
    }

    // CAGradientLayer.colors and the layer shadow are static CGColors that do not flip with the
    // trait — refresh manually when the system switches light/dark.
    private func applyColorAppearanceChange() {
        updateBackground()
        updateActiveState()
    }
    
    // MARK: - Setup
    private func setupViews() {
        layer.insertSublayer(gradientLayer, at: 0)
        
        topLine.backgroundColor = ILColors.border
        topLine.translatesAutoresizingMaskIntoConstraints = false
        
        contentStack.axis = .horizontal
        contentStack.distribution = .fillEqually
        contentStack.alignment = .bottom
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(topLine)
        addSubview(contentStack)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: ILMetrics.bottomNavHeight),
            topLine.topAnchor.constraint(equalTo: topAnchor),
            topLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            topLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            topLine.heightAnchor.constraint(equalToConstant: 1),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -8),
            contentStack.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 10)
        ])
        
        setupTabs()
        updateBackground()
        updateActiveState()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILBottomNavBar, _) in
            view.applyColorAppearanceChange()
        }
    }
    
    private func setupTabs() {
        for tab in Tab.allCases {
            if tab == .lamp {
                let lampContainer = UIView()
                lampContainer.translatesAutoresizingMaskIntoConstraints = false
                
                lampButton.translatesAutoresizingMaskIntoConstraints = false
                lampButton.addTarget(self, action: #selector(handleTabTap(_:)), for: .touchUpInside)
                lampButton.tag = Tab.allCases.firstIndex(of: .lamp) ?? 2
                lampButton.accessibilityLabel = "Đèn thiền"
                
                lampContainer.addSubview(lampButton)
                
                // 48×48 button floating in the middle; its bottom meets the bottom of the other
                // tabs' labels (the prototype row uses `align-items:flex-end`).
                NSLayoutConstraint.activate([
                    lampButton.centerXAnchor.constraint(equalTo: lampContainer.centerXAnchor),
                    lampButton.widthAnchor.constraint(equalToConstant: 48),
                    lampButton.heightAnchor.constraint(equalToConstant: 48),
                    lampButton.topAnchor.constraint(equalTo: lampContainer.topAnchor),
                    lampButton.bottomAnchor.constraint(equalTo: lampContainer.bottomAnchor, constant: -4)
                ])
                
                contentStack.addArrangedSubview(lampContainer)
                continue
            }
            
            let itemControl = UIControl()
            itemControl.translatesAutoresizingMaskIntoConstraints = false
            itemControl.tag = Tab.allCases.firstIndex(of: tab) ?? 0
            itemControl.addTarget(self, action: #selector(handleTabTap(_:)), for: .touchUpInside)
            
            let iconView = UIImageView(image: tab.icon)
            iconView.translatesAutoresizingMaskIntoConstraints = false
            iconView.contentMode = .scaleAspectFit
            iconView.isUserInteractionEnabled = false
            
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.isUserInteractionEnabled = false
            label.font = ILTypography.captionSmall
            label.textAlignment = .center
            label.text = tab.title
            
            let itemStack = UIStackView(arrangedSubviews: [iconView, label])
            itemStack.axis = .vertical
            itemStack.spacing = 4
            itemStack.alignment = .center
            itemStack.isUserInteractionEnabled = false
            itemStack.translatesAutoresizingMaskIntoConstraints = false
            
            itemControl.addSubview(itemStack)
            
            NSLayoutConstraint.activate([
                iconView.widthAnchor.constraint(equalToConstant: 24),
                iconView.heightAnchor.constraint(equalToConstant: 24),
                
                itemStack.centerXAnchor.constraint(equalTo: itemControl.centerXAnchor),
                itemStack.bottomAnchor.constraint(equalTo: itemControl.bottomAnchor, constant: -4),
                itemStack.topAnchor.constraint(greaterThanOrEqualTo: itemControl.topAnchor)
            ])
            
            tabButtons[tab] = itemControl
            iconViews[tab] = iconView
            labelViews[tab] = label
            
            contentStack.addArrangedSubview(itemControl)
        }
    }
    
    /// Light: solid card (`surface`) + hairline + soft upward shadow.
    /// Dark: fade from transparent to `surface`, no hairline / shadow.
    private func updateBackground() {
        let surface = ILColors.surface.resolvedColor(with: traitCollection)
        if isDark {
            gradientLayer.colors = [surface.withAlphaComponent(0.0).cgColor, surface.cgColor]
            gradientLayer.locations = [0.0, 0.34]
            layer.shadowOpacity = 0
        } else {
            gradientLayer.colors = [surface.cgColor, surface.cgColor]
            gradientLayer.locations = [0.0, 1.0]
            ILMetrics.shadowBottomNav.apply(to: layer)
            layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        }
        topLine.isHidden = isDark
    }

    private func updateActiveState() {
        // Colors follow `renderVals()` of `IL-BottomNav.dc.html`:
        // - active: `goldDeep` in light, `goldBright` in dark
        // - inactive: `ink` alpha 0.42 in light, 0.50 in dark (the `ink` asset flips with the theme)
        let activeColor = isDark ? ILColors.goldBright : ILColors.goldDeep
        let inactiveColor = isDark ? ILColors.inkTertiary : ILColors.inkMuted
        
        for tab in Tab.allCases where tab != .lamp {
            let color = tab == activeTab ? activeColor : inactiveColor
            iconViews[tab]?.tintColor = color
            labelViews[tab]?.textColor = color
        }
        
        lampButton.applyAppearance(isDark: isDark)
    }
    
    @objc private func handleTabTap(_ sender: UIControl) {
        guard sender.tag < Tab.allCases.count else { return }
        let selectedTab = Tab.allCases[sender.tag]
        if selectedTab != .lamp {
            activeTab = selectedTab
        }
        onTabSelected?(selectedTab)
    }
}

// MARK: - Lamp Button

/// Center lamp button of `ILBottomNavBar`: 48×48 disc + two-layer flame (outer flame + inner core).
/// Light: gold gradient (160°) disc with a pale flame; dark: flat `goldBright` disc with a dark flame.
private final class ILLampButton: UIButton {

    private let backdropLayer = CAGradientLayer()
    private let flameView = UIImageView(image: ILIcons.tabLampFlame)
    private let coreView = UIImageView(image: ILIcons.tabLampCore)

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.insertSublayer(backdropLayer, at: 0)

        for glyph in [flameView, coreView] {
            glyph.translatesAutoresizingMaskIntoConstraints = false
            glyph.contentMode = .scaleAspectFit
            glyph.isUserInteractionEnabled = false
            addSubview(glyph)
            NSLayoutConstraint.activate([
                glyph.centerXAnchor.constraint(equalTo: centerXAnchor),
                // The prototype nudges the flame up by 1pt (`margin-top:-2px` in a centered flex row).
                glyph.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -1),
                glyph.widthAnchor.constraint(equalToConstant: 17),
                glyph.heightAnchor.constraint(equalToConstant: 24)
            ])
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.8 : 1.0 }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        backdropLayer.frame = bounds
        backdropLayer.cornerRadius = bounds.height / 2
        layer.shadowPath = UIBezierPath(ovalIn: bounds).cgPath
    }

    func applyAppearance(isDark: Bool) {
        if isDark {
            backdropLayer.colors = [ILColors.goldBright.cgColor, ILColors.goldBright.cgColor]
            flameView.tintColor = ILColors.lampFlameDark
            coreView.tintColor = ILColors.lampFlameDark.withAlphaComponent(0.55)
            ILMetrics.shadowLampDark.apply(to: layer)
        } else {
            // CSS `linear-gradient(160deg, …)` on a square: from the top-left toward the bottom-right.
            backdropLayer.startPoint = CGPoint(x: 0.329, y: 0.03)
            backdropLayer.endPoint = CGPoint(x: 0.671, y: 0.97)
            backdropLayer.colors = [ILColors.lampFlameLight.cgColor, ILColors.gold.cgColor]
            flameView.tintColor = ILColors.lampGlyphLight
            coreView.tintColor = ILColors.gold.withAlphaComponent(0.55)
            ILMetrics.shadowLampLight.apply(to: layer)
        }
        layer.shadowPath = UIBezierPath(ovalIn: bounds).cgPath
    }
}
