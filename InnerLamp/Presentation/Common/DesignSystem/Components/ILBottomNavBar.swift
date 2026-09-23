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
            case .sangha: return "Đạo tràng"
            case .me: return "Tôi"
            }
        }
    }
    
    // MARK: - Properties
    public var activeTab: Tab = .home {
        didSet { updateActiveState() }
    }
    
    /// Đọc trực tiếp trait hệ thống — không cache thủ công để không bị lệch khi
    /// người dùng đổi theme lúc app đang chạy (`traitCollectionDidChange` sẽ refresh lại).
    private var isDark: Bool { traitCollection.userInterfaceStyle == .dark }

    public var onTabSelected: ((Tab) -> Void)?
    
    // MARK: - UI Elements
    private let gradientLayer = CAGradientLayer()
    private let contentStack = UIStackView()
    
    private var tabButtons: [Tab: UIControl] = [:]
    private var iconViews: [Tab: UIView] = [:]
    private var labelViews: [Tab: UILabel] = [:]
    private let lampButton = UIButton(type: .custom)
    private let lampFlame = ILLampFlameView()
    
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
    }

    // Gradient (CAGradientLayer.colors) và layer.borderColor là CGColor tĩnh, không tự
    // đảo theo trait — refresh thủ công khi hệ thống đổi light/dark.
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateGradient()
        updateActiveState()
    }
    
    // MARK: - Setup
    private func setupViews() {
        layer.insertSublayer(gradientLayer, at: 0)
        
        contentStack.axis = .horizontal
        contentStack.distribution = .fillEqually
        contentStack.alignment = .bottom
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(contentStack)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: ILMetrics.bottomNavHeight),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -8),
            contentStack.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 10)
        ])
        
        setupTabs()
        updateGradient()
        updateActiveState()
    }
    
    private func setupTabs() {
        for tab in Tab.allCases {
            if tab == .lamp {
                let lampContainer = UIView()
                lampContainer.translatesAutoresizingMaskIntoConstraints = false
                
                lampButton.translatesAutoresizingMaskIntoConstraints = false
                lampButton.layer.cornerRadius = 24.0
                lampButton.addTarget(self, action: #selector(handleTabTap(_:)), for: .touchUpInside)
                lampButton.tag = Tab.allCases.firstIndex(of: .lamp) ?? 2
                
                lampFlame.translatesAutoresizingMaskIntoConstraints = false
                
                lampButton.addSubview(lampFlame)
                lampContainer.addSubview(lampButton)
                
                // Nút 48×48 nổi ở giữa; đáy nút trùng đáy nhãn các tab còn lại
                // (prototype: hàng dùng `align-items:flex-end`, đáy vòng đèn ngang đáy nhãn).
                NSLayoutConstraint.activate([
                    lampButton.centerXAnchor.constraint(equalTo: lampContainer.centerXAnchor),
                    lampButton.widthAnchor.constraint(equalToConstant: 48),
                    lampButton.heightAnchor.constraint(equalToConstant: 48),
                    lampButton.topAnchor.constraint(equalTo: lampContainer.topAnchor),
                    lampButton.bottomAnchor.constraint(equalTo: lampContainer.bottomAnchor, constant: -4),
                    
                    lampFlame.centerXAnchor.constraint(equalTo: lampButton.centerXAnchor),
                    lampFlame.centerYAnchor.constraint(equalTo: lampButton.centerYAnchor),
                    lampFlame.widthAnchor.constraint(equalToConstant: 14),
                    lampFlame.heightAnchor.constraint(equalToConstant: 20)
                ])
                
                contentStack.addArrangedSubview(lampContainer)
                continue
            }
            
            let itemControl = UIControl()
            itemControl.translatesAutoresizingMaskIntoConstraints = false
            itemControl.tag = Tab.allCases.firstIndex(of: tab) ?? 0
            itemControl.addTarget(self, action: #selector(handleTabTap(_:)), for: .touchUpInside)
            
            let iconContainer = UIView()
            iconContainer.translatesAutoresizingMaskIntoConstraints = false
            iconContainer.isUserInteractionEnabled = false
            iconContainer.layer.borderWidth = 1.6
            
            switch tab {
            case .home:
                iconContainer.layer.cornerRadius = 5.0
            case .lib:
                iconContainer.layer.cornerRadius = 2.0
            case .sangha:
                iconContainer.layer.cornerRadius = 9.0
            case .me:
                iconContainer.layer.cornerRadius = 9.0
            default:
                break
            }
            
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.isUserInteractionEnabled = false
            label.font = ILTypography.captionSmall
            label.textAlignment = .center
            label.text = tab.title
            
            let itemStack = UIStackView(arrangedSubviews: [iconContainer, label])
            itemStack.axis = .vertical
            itemStack.spacing = 5
            itemStack.alignment = .center
            itemStack.isUserInteractionEnabled = false
            itemStack.translatesAutoresizingMaskIntoConstraints = false
            
            itemControl.addSubview(itemStack)
            
            NSLayoutConstraint.activate([
                iconContainer.widthAnchor.constraint(equalToConstant: tab == .lib ? 16 : 18),
                iconContainer.heightAnchor.constraint(equalToConstant: 18),
                
                itemStack.centerXAnchor.constraint(equalTo: itemControl.centerXAnchor),
                itemStack.bottomAnchor.constraint(equalTo: itemControl.bottomAnchor, constant: -4),
                itemStack.topAnchor.constraint(greaterThanOrEqualTo: itemControl.topAnchor)
            ])
            
            tabButtons[tab] = itemControl
            iconViews[tab] = iconContainer
            labelViews[tab] = label
            
            contentStack.addArrangedSubview(itemControl)
        }
    }
    
    private func updateGradient() {
        // Fade từ trong suốt lên đúng màu canvas hiện tại (asset tự đảo theo trait) —
        // luôn khớp nền phía sau, không cần set cứng 2 bộ hex riêng cho light/dark.
        gradientLayer.colors = [
            ILColors.canvas.withAlphaComponent(0.0).cgColor,
            ILColors.canvas.cgColor
        ]
        gradientLayer.locations = isDark ? [0.0, 0.34] : [0.0, 0.32]
    }

    private func updateActiveState() {
        let activeColor = ILColors.ink
        let inactiveColor = ILColors.ink.withAlphaComponent(0.40)
        
        for tab in Tab.allCases where tab != .lamp {
            let isCurrent = tab == activeTab
            let color = isCurrent ? activeColor : inactiveColor
            
            iconViews[tab]?.layer.borderColor = color.cgColor
            labelViews[tab]?.textColor = color
        }
        
        // Lamp button — nền và bóng đổi theo theme; ngọn lửa tự cập nhật màu theo trait.
        if isDark {
            lampButton.backgroundColor = ILColors.goldBright
            ILMetrics.shadowLampDark.apply(to: lampButton.layer)
        } else {
            lampButton.backgroundColor = ILColors.ink
            ILMetrics.shadowLampLight.apply(to: lampButton.layer)
        }
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

// MARK: - Lamp Flame

/// Ngọn lửa bên trong nút Đèn ở giữa `ILBottomNavBar`.
///
/// Hình dạng lấy đúng theo `IL-BottomNav.dc.html`
/// (`border-radius: 50% 50% 45% 45% / 62% 62% 38% 38%`): nửa elip phía trên nối hai góc
/// dưới bo elip nhỏ hơn — không phải hình bầu dục bo đều. Màu: chế độ sáng là gradient dọc
/// `#F3C673 → #D9963C`, chế độ tối là màu đặc `#1A1611` (bấc đèn trên nền vàng).
final class ILLampFlameView: UIView {

    private enum Layout {
        /// Hệ số Bezier xấp xỉ ¼ elip.
        static let kappa: CGFloat = 0.5523
        /// Tâm bo góc trên / đỉnh bo góc dưới (theo chiều cao).
        static let upperCenterY: CGFloat = 0.62
        static let topRadiusX: CGFloat = 0.50
        static let topRadiusY: CGFloat = 0.62
        static let bottomRadiusX: CGFloat = 0.45
        static let bottomRadiusY: CGFloat = 0.38
    }

    private let gradientLayer = CAGradientLayer()
    private let shapeMask = CAShapeLayer()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear

        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.mask = shapeMask
        layer.addSublayer(gradientLayer)

        updateColors()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        shapeMask.frame = bounds
        shapeMask.path = Self.flamePath(in: bounds).cgPath
    }

    // `CAGradientLayer.colors` là CGColor tĩnh, không tự đảo theo trait — refresh thủ công.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateColors()
    }

    private func updateColors() {
        if traitCollection.userInterfaceStyle == .dark {
            let wick = ILColors.lampFlameDark.cgColor
            gradientLayer.colors = [wick, wick]
        } else {
            gradientLayer.colors = [ILColors.goldSoft.cgColor, ILColors.goldBright.cgColor]
        }
    }

    /// Đường bao ngọn lửa trong `rect`, dựng theo tỉ lệ bo góc của prototype.
    private static func flamePath(in rect: CGRect) -> UIBezierPath {
        let width = rect.width
        let height = rect.height
        let kappa = Layout.kappa

        let centerY = Layout.upperCenterY * height
        let topRadiusX = Layout.topRadiusX * width
        let topRadiusY = Layout.topRadiusY * height
        let bottomRadiusX = Layout.bottomRadiusX * width
        let bottomRadiusY = Layout.bottomRadiusY * height

        let topCenter = CGPoint(x: width / 2, y: 0)
        let rightUpper = CGPoint(x: width, y: centerY)
        let rightLower = CGPoint(x: width - bottomRadiusX, y: height)
        let leftLower = CGPoint(x: bottomRadiusX, y: height)
        let leftUpper = CGPoint(x: 0, y: centerY)

        let path = UIBezierPath()
        path.move(to: leftUpper)
        // Nửa elip trên: (0, centerY) → đỉnh → (width, centerY).
        path.addCurve(
            to: topCenter,
            controlPoint1: CGPoint(x: leftUpper.x, y: centerY - kappa * topRadiusY),
            controlPoint2: CGPoint(x: topCenter.x - kappa * topRadiusX, y: topCenter.y)
        )
        path.addCurve(
            to: rightUpper,
            controlPoint1: CGPoint(x: topCenter.x + kappa * topRadiusX, y: topCenter.y),
            controlPoint2: CGPoint(x: rightUpper.x, y: centerY - kappa * topRadiusY)
        )
        // Góc dưới phải.
        path.addCurve(
            to: rightLower,
            controlPoint1: CGPoint(x: rightUpper.x, y: centerY + kappa * bottomRadiusY),
            controlPoint2: CGPoint(x: rightLower.x + kappa * bottomRadiusX, y: height)
        )
        // Đáy.
        path.addLine(to: leftLower)
        // Góc dưới trái.
        path.addCurve(
            to: leftUpper,
            controlPoint1: CGPoint(x: leftLower.x - kappa * bottomRadiusX, y: height),
            controlPoint2: CGPoint(x: leftUpper.x, y: centerY + kappa * bottomRadiusY)
        )
        path.close()
        return path
    }
}
