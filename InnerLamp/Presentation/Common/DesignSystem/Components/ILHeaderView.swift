//
//  ILHeaderView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 11/9/26.
//

import UIKit

public final class ILHeaderView: UIView {
    
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
    
    public var rightActionTitle: String = "" {
        didSet {
            rightButton.setTitle(rightActionTitle, for: .normal)
            updateActionButtonVisibility()
        }
    }

    public var isCloseButton: Bool = false {
        didSet {
            backButton.setTitle(isCloseButton ? "✕" : "‹", for: .normal)
            backButton.titleLabel?.font = ILTypography.beVietnamPro(size: isCloseButton ? 16 : 24, weight: .regular)
        }
    }

    /// Explicit override to hide the back/close button (e.g. root tab screens).
    public var isBackButtonHidden: Bool = false {
        didSet { backButton.isHidden = isBackButtonHidden }
    }

    /// Explicit override to hide the right action button even when `rightActionTitle` is set.
    public var isActionButtonHidden: Bool = false {
        didSet { updateActionButtonVisibility() }
    }

    public var onBack: (() -> Void)?
    public var onAction: (() -> Void)?
    
    // MARK: - UI Elements
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let subLabel = UILabel()
    private let textStack = UIStackView()
    private let rightButton = UIButton(type: .system)
    
    // MARK: - Initializer
    public init(
        title: String = "",
        subtitle: String = "",
        rightActionTitle: String = "",
        isCloseButton: Bool = false,
        isBackButtonHidden: Bool = false,
        isActionButtonHidden: Bool = false
    ) {
        self.title = title
        self.subtitle = subtitle
        self.rightActionTitle = rightActionTitle
        self.isCloseButton = isCloseButton
        self.isBackButtonHidden = isBackButtonHidden
        self.isActionButtonHidden = isActionButtonHidden
        super.init(frame: .zero)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupViews() {
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setTitle(isCloseButton ? "✕" : "‹", for: .normal)
        backButton.titleLabel?.font = ILTypography.beVietnamPro(size: isCloseButton ? 16 : 24, weight: .regular)
        backButton.contentHorizontalAlignment = .leading
        backButton.addTarget(self, action: #selector(handleBackAction), for: .touchUpInside)
        backButton.isHidden = isBackButtonHidden
        
        titleLabel.font = ILTypography.headerTitle
        titleLabel.textAlignment = .center
        titleLabel.text = title
        
        subLabel.font = ILTypography.caption
        subLabel.textAlignment = .center
        subLabel.text = subtitle
        subLabel.isHidden = subtitle.isEmpty
        
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .center
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subLabel)
        
        rightButton.translatesAutoresizingMaskIntoConstraints = false
        rightButton.setTitle(rightActionTitle, for: .normal)
        rightButton.titleLabel?.font = ILTypography.bodySmallMedium
        rightButton.setTitleColor(ILColors.goldDeep, for: .normal)
        rightButton.contentHorizontalAlignment = .trailing
        rightButton.addTarget(self, action: #selector(handleRightAction), for: .touchUpInside)
        updateActionButtonVisibility()
        
        addSubview(backButton)
        addSubview(textStack)
        addSubview(rightButton)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: ILMetrics.headerHeight),
            
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            textStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            textStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            textStack.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 8),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: rightButton.leadingAnchor, constant: -8),
            
            rightButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            rightButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            rightButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
            rightButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        updateAppearance()
    }
    
    private func updateActionButtonVisibility() {
        rightButton.isHidden = rightActionTitle.isEmpty || isActionButtonHidden
    }

    private func updateAppearance() {
        // Token động (ink*) tự đảo theo trait — không cần nhánh isDark thủ công.
        backButton.setTitleColor(ILColors.inkTertiary, for: .normal)
        titleLabel.textColor = ILColors.ink
        subLabel.textColor = ILColors.inkTertiary
        rightButton.setTitleColor(ILColors.goldDeep, for: .normal)
    }
    
    @objc private func handleBackAction() {
        onBack?()
    }
    
    @objc private func handleRightAction() {
        onAction?()
    }
}
