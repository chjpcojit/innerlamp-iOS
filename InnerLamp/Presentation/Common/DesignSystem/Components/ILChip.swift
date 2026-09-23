//
//  ILChip.swift
//  InnerLamp
//
//  Created by ChjpCoj on 11/9/26.
//

import UIKit

public final class ILChip: UIControl {
    
    public enum State {
        case normal
        case selected
        case disabled
    }
    
    // MARK: - Properties
    public var chipState: State = .normal {
        didSet {
            isEnabled = chipState != .disabled
            updateAppearance()
        }
    }
    
    public var label: String = "" {
        didSet { titleLabel.text = label }
    }
    
    public var count: String? {
        didSet {
            countLabel.text = count
            countLabel.isHidden = (count == nil || count?.isEmpty == true)
        }
    }
    
    public var hasDot: Bool = false {
        didSet { dotView.isHidden = !hasDot }
    }
    
    public var onTap: (() -> Void)?
    
    // MARK: - UI Elements
    private let stackView = UIStackView()
    private let dotView = UIView()
    private let titleLabel = UILabel()
    private let countLabel = UILabel()
    
    // MARK: - Initializer
    public init(
        label: String,
        count: String? = nil,
        hasDot: Bool = false,
        state: State = .normal
    ) {
        self.label = label
        self.count = count
        self.hasDot = hasDot
        self.chipState = state
        super.init(frame: .zero)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupViews() {
        layer.cornerRadius = 17.0
        layer.masksToBounds = true
        
        dotView.translatesAutoresizingMaskIntoConstraints = false
        dotView.layer.cornerRadius = 3.5
        dotView.clipsToBounds = true
        dotView.isHidden = !hasDot
        NSLayoutConstraint.activate([
            dotView.widthAnchor.constraint(equalToConstant: 7),
            dotView.heightAnchor.constraint(equalToConstant: 7)
        ])
        
        titleLabel.font = ILTypography.chip
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.text = label
        
        countLabel.font = ILTypography.caption
        countLabel.setContentHuggingPriority(.required, for: .horizontal)
        countLabel.text = count
        countLabel.isHidden = (count == nil || count?.isEmpty == true)
        
        stackView.axis = .horizontal
        stackView.spacing = 7
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.isUserInteractionEnabled = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(dotView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(countLabel)
        
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 34),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)
        
        updateAppearance()
    }
    
    private func updateAppearance() {
        let isSelected = chipState == .selected
        let isDisabled = chipState == .disabled

        dotView.backgroundColor = isSelected ? ILColors.goldBright : ILColors.gold

        // Dùng token động (ink/surface/canvas tự đảo theo trait) thay vì set cứng
        // 2 bộ hex riêng cho light/dark — tự đúng cả 2 mode, kể cả đổi theme lúc app chạy.
        if isDisabled {
            backgroundColor = ILColors.ink.withAlphaComponent(0.04)
            titleLabel.textColor = ILColors.ink.withAlphaComponent(0.32)
            countLabel.textColor = titleLabel.textColor
            layer.borderWidth = 0
            layer.borderColor = nil
            return
        }

        layer.borderWidth = 1

        if isSelected {
            backgroundColor = ILColors.ink
            titleLabel.textColor = ILColors.canvas
            countLabel.textColor = ILColors.canvas.withAlphaComponent(0.60)
            layer.borderColor = ILColors.ink.cgColor
        } else {
            backgroundColor = ILColors.surface
            titleLabel.textColor = ILColors.ink.withAlphaComponent(0.70)
            countLabel.textColor = ILColors.ink.withAlphaComponent(0.42)
            layer.borderColor = ILColors.ink.withAlphaComponent(0.14).cgColor
        }
    }

    // `layer.borderColor` là CGColor tĩnh, không tự đảo theo trait — refresh thủ công
    // khi hệ thống đổi light/dark (ink/surface giờ có biến thể dark).
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateAppearance()
    }
    
    @objc private func handleTouchDown() {
        guard chipState != .disabled else { return }
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }
    }
    
    @objc private func handleTouchUp() {
        guard chipState != .disabled else { return }
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = .identity
        }
    }
    
    @objc private func handleTapAction() {
        guard chipState != .disabled else { return }
        onTap?()
    }
}
