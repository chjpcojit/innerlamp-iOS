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

        /// Icon SVG của tab trong `IL-BottomNav.dc.html`. `.lamp` không có icon (nút Đèn riêng).
        var iconKind: ILTabIconView.Kind {
            switch self {
            case .home: return .home
            case .lib: return .lib
            case .sangha: return .sangha
            case .me: return .me
            case .lamp: return .home
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
    private var iconViews: [Tab: ILTabIconView] = [:]
    private var labelViews: [Tab: UILabel] = [:]
    private let lampButton = UIButton(type: .custom)
    
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
    private func applyColorAppearanceChange() {
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
                lampButton.layer.cornerRadius = 24.0
                lampButton.addTarget(self, action: #selector(handleTabTap(_:)), for: .touchUpInside)
                lampButton.tag = Tab.allCases.firstIndex(of: .lamp) ?? 2
                // Icon template — bản đặc khi thường, bản nét khi đang nhấn; màu theo `tintColor`.
                lampButton.setImage(ILIcons.tabLampFilled, for: .normal)
                lampButton.setImage(ILIcons.tabLampOutline, for: .highlighted)
                lampButton.accessibilityLabel = "Đèn thiền"
                
                lampContainer.addSubview(lampButton)
                
                // Nút 48×48 nổi ở giữa; đáy nút trùng đáy nhãn các tab còn lại
                // (prototype: hàng dùng `align-items:flex-end`, đáy vòng đèn ngang đáy nhãn).
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
            
            // Icon SVG 22×22 theo `IL-BottomNav.dc.html` — vẽ bằng CAShapeLayer (nét 1.6, bo tròn),
            // không còn là khung vuông bo placeholder.
            let iconView = ILTabIconView(kind: tab.iconKind)
            iconView.translatesAutoresizingMaskIntoConstraints = false
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
                iconView.widthAnchor.constraint(equalToConstant: 22),
                iconView.heightAnchor.constraint(equalToConstant: 22),
                
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
        // Màu theo `renderVals()` của `IL-BottomNav.dc.html`:
        // - nét active: `--il-ink` ở sáng, `#D9963C` (goldBright) ở tối
        // - nét inactive: `--il-ink` alpha 0.40 (asset tự đảo nên dùng chung cả 2 chế độ)
        // - fill nhẹ khi active: `--il-ink-12` ở sáng, `rgba(217,150,60,.22)` ở tối
        let activeColor = isDark ? ILColors.goldBright : ILColors.ink
        let inactiveColor = ILColors.ink.withAlphaComponent(0.40)
        let activeFill = isDark
            ? ILColors.goldBright.withAlphaComponent(0.22)
            : ILColors.ink.withAlphaComponent(0.12)
        
        for tab in Tab.allCases where tab != .lamp {
            let isCurrent = tab == activeTab
            let color = isCurrent ? activeColor : inactiveColor
            
            iconViews[tab]?.strokeColor = color
            iconViews[tab]?.fillColor = isCurrent ? activeFill : nil
            labelViews[tab]?.textColor = color
        }
        
        // Lamp button — nền, bóng và màu icon đổi theo theme
        // (sáng: đèn vàng trên nền mực; tối: đèn sẫm trên nền vàng).
        if isDark {
            lampButton.backgroundColor = ILColors.goldBright
            lampButton.tintColor = ILColors.lampFlameDark
            ILMetrics.shadowLampDark.apply(to: lampButton.layer)
        } else {
            lampButton.backgroundColor = ILColors.ink
            lampButton.tintColor = ILColors.lampFlameLight
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

// MARK: - Tab Icon

/// Icon vector 22×22 cho từng tab — dựng lại đúng các path SVG trong `IL-BottomNav.dc.html`
/// (viewBox 24×24, nét 1.6 bo tròn). Một layer stroke vẽ toàn bộ nét; một layer fill tô các
/// phần "đặc" (cửa mái chùa, trang sách, đầu người) — chỉ khi tab active.
final class ILTabIconView: UIView {

    enum Kind {
        case home, lib, sangha, me
    }

    /// Màu nét outline. Gán lại khi đổi theme / trạng thái active.
    var strokeColor: UIColor = .clear {
        didSet { strokeLayer.strokeColor = strokeColor.cgColor }
    }

    /// Màu tô phần đặc; `nil` = chỉ vẽ nét (tab inactive).
    var fillColor: UIColor? {
        didSet { fillLayer.fillColor = fillColor?.cgColor }
    }

    private let kind: Kind
    private let strokeLayer = CAShapeLayer()
    private let fillLayer = CAShapeLayer()

    init(kind: Kind) {
        self.kind = kind
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        backgroundColor = .clear

        strokeLayer.fillColor = nil
        strokeLayer.lineWidth = 1.6
        strokeLayer.lineCap = .round
        strokeLayer.lineJoin = .round
        layer.addSublayer(strokeLayer)

        fillLayer.strokeColor = nil
        layer.addSublayer(fillLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        strokeLayer.frame = bounds
        fillLayer.frame = bounds

        // Path soạn trong không gian 24×24 như viewBox SVG; scale vào bounds 22×22.
        let scale = bounds.width / 24
        let transform = CGAffineTransform(scaleX: scale, y: scale)

        let stroke = Self.strokePath(for: kind)
        stroke.apply(transform)
        strokeLayer.path = stroke.cgPath

        let fill = Self.fillPath(for: kind)
        fill.apply(transform)
        fillLayer.path = fill.cgPath
    }

    // MARK: - Path builders (24×24 design space)

    /// Toàn bộ nét outline của icon — nhiều subpath trong một `UIBezierPath`.
    private static func strokePath(for kind: Kind) -> UIBezierPath {
        let path = UIBezierPath()
        switch kind {
        case .home:
            // Mái chùa: đỉnh + mái cong + tường + cửa vòm.
            path.move(to: CGPoint(x: 12, y: 2.5))
            path.addLine(to: CGPoint(x: 12, y: 4.5))

            path.move(to: CGPoint(x: 4, y: 11.5))
            path.addCurve(
                to: CGPoint(x: 12, y: 5),
                controlPoint1: CGPoint(x: 7, y: 10.5),
                controlPoint2: CGPoint(x: 9.5, y: 8.2)
            )
            path.addCurve(
                to: CGPoint(x: 20, y: 11.5),
                controlPoint1: CGPoint(x: 14.5, y: 8.2),
                controlPoint2: CGPoint(x: 17, y: 10.5)
            )

            path.move(to: CGPoint(x: 6, y: 11))
            path.addLine(to: CGPoint(x: 6, y: 20))
            path.addLine(to: CGPoint(x: 18, y: 20))
            path.addLine(to: CGPoint(x: 18, y: 11))

            doorPath(in: path)

        case .lib:
            // Kinh sách mở: bìa mở hai bên + gáy giữa.
            bookPath(in: path)
            path.move(to: CGPoint(x: 12, y: 6.5))
            path.addLine(to: CGPoint(x: 12, y: 19.5))

        case .sangha:
            // Người trong nhóm: thân + đầu lớn ở giữa, hai người nhỏ hai bên.
            path.move(to: CGPoint(x: 6, y: 20))
            path.addCurve(
                to: CGPoint(x: 12, y: 14),
                controlPoint1: CGPoint(x: 6, y: 16.5),
                controlPoint2: CGPoint(x: 8.7, y: 14)
            )
            path.addCurve(
                to: CGPoint(x: 18, y: 20),
                controlPoint1: CGPoint(x: 15.3, y: 14),
                controlPoint2: CGPoint(x: 18, y: 16.5)
            )
            path.append(UIBezierPath(ovalIn: CGRect(x: 9, y: 4.5, width: 6, height: 6)))

            path.append(UIBezierPath(ovalIn: CGRect(x: 2.9, y: 8.1, width: 3.8, height: 3.8)))
            path.append(UIBezierPath(ovalIn: CGRect(x: 17.3, y: 8.1, width: 3.8, height: 3.8)))

            path.move(to: CGPoint(x: 2, y: 18.5))
            path.addCurve(
                to: CGPoint(x: 5, y: 14.5),
                controlPoint1: CGPoint(x: 2, y: 16.5),
                controlPoint2: CGPoint(x: 3.2, y: 14.9)
            )
            path.move(to: CGPoint(x: 22, y: 18.5))
            path.addCurve(
                to: CGPoint(x: 19, y: 14.5),
                controlPoint1: CGPoint(x: 22, y: 16.5),
                controlPoint2: CGPoint(x: 20.8, y: 14.9)
            )

        case .me:
            // Người: đầu + vai/thân.
            path.append(UIBezierPath(ovalIn: CGRect(x: 8.4, y: 4.4, width: 7.2, height: 7.2)))
            path.move(to: CGPoint(x: 4.5, y: 20.5))
            path.addCurve(
                to: CGPoint(x: 12, y: 14),
                controlPoint1: CGPoint(x: 5.3, y: 16.5),
                controlPoint2: CGPoint(x: 8.3, y: 14)
            )
            path.addCurve(
                to: CGPoint(x: 19.5, y: 20.5),
                controlPoint1: CGPoint(x: 15.7, y: 14),
                controlPoint2: CGPoint(x: 18.7, y: 16.5)
            )
        }
        return path
    }

    /// Phần "đặc" được tô khi active (fill nhẹ) — chỉ gồm các subpath có `fill` trong SVG.
    private static func fillPath(for kind: Kind) -> UIBezierPath {
        let path = UIBezierPath()
        switch kind {
        case .home:
            doorPath(in: path)
            path.close()
        case .lib:
            bookPath(in: path)
            path.close()
        case .sangha:
            path.append(UIBezierPath(ovalIn: CGRect(x: 9, y: 4.5, width: 6, height: 6)))
        case .me:
            path.append(UIBezierPath(ovalIn: CGRect(x: 8.4, y: 4.4, width: 7.2, height: 7.2)))
        }
        return path
    }

    // MARK: - Shared subpaths

    /// Cửa vòm mái chùa (`M10 20v-4.5a2 2 0 0 1 4 0V20`) — bo tròn phía trên.
    private static func doorPath(in path: UIBezierPath) {
        path.move(to: CGPoint(x: 10, y: 20))
        path.addLine(to: CGPoint(x: 10, y: 15.5))
        path.addArc(
            withCenter: CGPoint(x: 12, y: 15.5),
            radius: 2,
            startAngle: .pi,
            endAngle: 2 * .pi,
            clockwise: true
        )
        path.addLine(to: CGPoint(x: 14, y: 20))
    }

    /// Bìa sách mở (`M12 6.5C10 5 7 4.5 3.5 5v13c3.5-.5 6.5 0 8.5 1.5 2-1.5 5-2 8.5-1.5V5...z`).
    private static func bookPath(in path: UIBezierPath) {
        path.move(to: CGPoint(x: 12, y: 6.5))
        path.addCurve(
            to: CGPoint(x: 3.5, y: 5),
            controlPoint1: CGPoint(x: 10, y: 5),
            controlPoint2: CGPoint(x: 7, y: 4.5)
        )
        path.addLine(to: CGPoint(x: 3.5, y: 18))
        path.addCurve(
            to: CGPoint(x: 12, y: 19.5),
            controlPoint1: CGPoint(x: 7, y: 17.5),
            controlPoint2: CGPoint(x: 10, y: 18)
        )
        path.addCurve(
            to: CGPoint(x: 20.5, y: 18),
            controlPoint1: CGPoint(x: 14, y: 18),
            controlPoint2: CGPoint(x: 17, y: 17.5)
        )
        path.addLine(to: CGPoint(x: 20.5, y: 5))
        path.addCurve(
            to: CGPoint(x: 12, y: 6.5),
            controlPoint1: CGPoint(x: 17, y: 4.5),
            controlPoint2: CGPoint(x: 14, y: 5)
        )
    }
}
