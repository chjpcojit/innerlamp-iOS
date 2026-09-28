//
//  ILButton.swift
//  InnerLamp
//
//  Created by ChjpCoj on 11/9/26.
//

import UIKit

public final class ILButton: UIControl {
    
    public enum Variant {
        case primary
        case gold
        /// Viền vàng nhạt, nền `surface`, chữ `goldDeep` — CTA phụ nổi bật hơn `.ghost`
        /// (vd. "Tạo tài khoản mới" ở màn Đăng nhập, design handoff `isLogin`).
        case goldOutline
        case ghost
        case light
        case onDark
        case danger
    }
    
    public enum State {
        case normal
        case loading
        case disabled
    }
    
    // MARK: - Properties
    public var variant: Variant = .primary {
        didSet { updateAppearance() }
    }
    
    public var buttonState: State = .normal {
        didSet {
            isEnabled = buttonState != .disabled
            isUserInteractionEnabled = buttonState == .normal
            updateAppearance()
        }
    }
    
    public var title: String = "" {
        didSet { updateTitle() }
    }
    
    public var loadingTitle: String = "Đang xử lý…" {
        didSet { updateTitle() }
    }
    
    public var onTap: (() -> Void)?
    
    // MARK: - UI Elements
    private let titleLabelCustom = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let contentStack = UIStackView()
    
    // MARK: - Initializer
    public init(
        title: String,
        variant: Variant = .primary,
        state: State = .normal,
        loadingTitle: String = "Đang xử lý…"
    ) {
        self.title = title
        self.variant = variant
        self.buttonState = state
        self.loadingTitle = loadingTitle
        super.init(frame: .zero)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupViews() {
        layer.cornerRadius = ILMetrics.buttonHeight / 2.0
        layer.masksToBounds = false
        
        titleLabelCustom.font = ILTypography.button
        titleLabelCustom.textAlignment = .center
        titleLabelCustom.setContentHuggingPriority(.required, for: .horizontal)
        
        spinner.hidesWhenStopped = true
        spinner.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        contentStack.axis = .horizontal
        contentStack.spacing = 9
        contentStack.alignment = .center
        contentStack.distribution = .fill
        contentStack.isUserInteractionEnabled = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentStack.addArrangedSubview(spinner)
        contentStack.addArrangedSubview(titleLabelCustom)
        
        addSubview(contentStack)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: ILMetrics.buttonHeight),
            contentStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16)
        ])
        
        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)
        
        updateAppearance()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILButton, _) in
            view.applyColorAppearanceChange()
        }
    }
    
    private func updateTitle() {
        if buttonState == .loading {
            titleLabelCustom.text = loadingTitle
        } else {
            titleLabelCustom.text = title
        }
    }
    
    private func updateAppearance() {
        updateTitle()
        
        if buttonState == .loading {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
        
        // Disabled State — dùng ILColors.ink (tự đảo theo trait) thay vì hex cứng
        // mô phỏng riêng giá trị light, nếu không nút disabled sẽ chìm mất ở dark mode.
        if buttonState == .disabled {
            backgroundColor = ILColors.ink.withAlphaComponent(0.12)
            titleLabelCustom.textColor = ILColors.ink.withAlphaComponent(0.38)
            layer.borderWidth = 0
            layer.borderColor = nil
            layer.shadowOpacity = 0
            spinner.color = ILColors.ink.withAlphaComponent(0.38)
            return
        }
        
        // Active Variants
        switch variant {
        case .primary:
            backgroundColor = ILColors.ink
            titleLabelCustom.textColor = ILColors.canvas
            layer.borderWidth = 1
            layer.borderColor = ILColors.ink.cgColor
            ILMetrics.shadowPrimaryButton.apply(to: layer)
            spinner.color = ILColors.canvas
            
        case .gold:
            backgroundColor = ILColors.gold
            titleLabelCustom.textColor = ILColors.surface
            layer.borderWidth = 1
            layer.borderColor = ILColors.gold.cgColor
            ILMetrics.shadowGoldButton.apply(to: layer)
            spinner.color = ILColors.surface
            
        case .goldOutline:
            backgroundColor = ILColors.surface
            titleLabelCustom.textColor = ILColors.goldDeep
            layer.borderWidth = 1
            layer.borderColor = ILColors.gold.withAlphaComponent(0.5).cgColor
            layer.shadowOpacity = 0
            spinner.color = ILColors.goldDeep

        case .ghost:
            backgroundColor = ILColors.surface
            titleLabelCustom.textColor = ILColors.ink
            layer.borderWidth = 1
            layer.borderColor = ILColors.borderStrong.cgColor
            layer.shadowOpacity = 0
            spinner.color = ILColors.ink
            
        case .light:
            backgroundColor = ILColors.inkOnDark
            titleLabelCustom.textColor = ILColors.ink
            layer.borderWidth = 1
            layer.borderColor = ILColors.inkOnDark.cgColor
            layer.shadowOpacity = 0
            spinner.color = ILColors.ink
            
        case .onDark:
            backgroundColor = .clear
            titleLabelCustom.textColor = ILColors.inkOnDark
            layer.borderWidth = 1
            layer.borderColor = ILColors.inkOnDarkVariant.withAlphaComponent(0.24).cgColor
            layer.shadowOpacity = 0
            spinner.color = ILColors.inkOnDark
            
        case .danger:
            backgroundColor = ILColors.surface
            titleLabelCustom.textColor = ILColors.danger
            layer.borderWidth = 1
            layer.borderColor = ILColors.danger.withAlphaComponent(0.40).cgColor
            layer.shadowOpacity = 0
            spinner.color = ILColors.danger
        }
    }
    
    // `layer.borderColor`/`shadowColor` là CGColor tĩnh, không tự đảo theo trait —
    // refresh thủ công khi hệ thống đổi light/dark (ink/surface giờ có biến thể dark).
    private func applyColorAppearanceChange() {
        updateAppearance()
    }

    // MARK: - Touch Animations
    @objc private func handleTouchDown() {
        guard buttonState == .normal else { return }
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = CGAffineTransform(scaleX: 0.978, y: 0.978)
        }
    }
    
    @objc private func handleTouchUp() {
        guard buttonState == .normal else { return }
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = .identity
        }
    }
    
    @objc private func handleTapAction() {
        guard buttonState == .normal else { return }
        onTap?()
    }
}
