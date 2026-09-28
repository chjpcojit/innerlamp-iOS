//
//  ILStateView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 11/9/26.
//

import UIKit

public final class ILStateView: UIView {
    
    public enum Kind {
        case empty
        case error
        case offline
        case done
    }
    
    // MARK: - Properties
    public var kind: Kind = .empty {
        didSet { updateAppearance() }
    }
    
    public var title: String = "" {
        didSet { titleLabel.text = title }
    }
    
    public var message: String = "" {
        didSet { messageLabel.text = message }
    }
    
    // MARK: - UI Elements
    private let iconCircle = UIView()
    private let glyphView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let stackView = UIStackView()
    
    // MARK: - Initializer
    public init(
        kind: Kind = .empty,
        title: String = "Chưa có gì ở đây",
        message: String = "Khi bạn bắt đầu thời khóa, mọi ghi nhận sẽ hiện ở đây."
    ) {
        self.kind = kind
        self.title = title
        self.message = message
        super.init(frame: .zero)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupViews() {
        iconCircle.translatesAutoresizingMaskIntoConstraints = false
        iconCircle.layer.cornerRadius = 44.0
        iconCircle.layer.borderWidth = 1
        
        glyphView.translatesAutoresizingMaskIntoConstraints = false
        iconCircle.addSubview(glyphView)
        
        NSLayoutConstraint.activate([
            iconCircle.widthAnchor.constraint(equalToConstant: 88),
            iconCircle.heightAnchor.constraint(equalToConstant: 88),
            glyphView.centerXAnchor.constraint(equalTo: iconCircle.centerXAnchor),
            glyphView.centerYAnchor.constraint(equalTo: iconCircle.centerYAnchor),
            glyphView.widthAnchor.constraint(equalToConstant: 26),
            glyphView.heightAnchor.constraint(equalToConstant: 26)
        ])
        
        titleLabel.font = ILTypography.scriptureTitle
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.text = title
        
        messageLabel.font = ILTypography.sectionTitle
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.text = message
        
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(iconCircle)
        stackView.setCustomSpacing(22, after: iconCircle)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(messageLabel)
        
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -24),
            messageLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 280)
        ])
        
        updateAppearance()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILStateView, _) in
            view.applyColorAppearanceChange()
        }
    }
    
    private func updateAppearance() {
        // Token động (ink*) tự đảo theo trait — không cần nhánh isDark thủ công.
        titleLabel.textColor = ILColors.ink
        messageLabel.textColor = ILColors.ink.withAlphaComponent(0.55)

        let accent: UIColor
        let alphaBg: CGFloat = 0.12

        switch kind {
        case .empty:
            accent = ILColors.gold
            iconCircle.backgroundColor = accent.withAlphaComponent(alphaBg)
            iconCircle.layer.borderColor = accent.withAlphaComponent(0.30).cgColor

            glyphView.backgroundColor = .clear
            glyphView.layer.borderWidth = 1.6
            glyphView.layer.borderColor = accent.cgColor
            glyphView.layer.cornerRadius = 13.0

        case .error:
            accent = ILColors.rose
            iconCircle.backgroundColor = accent.withAlphaComponent(alphaBg)
            iconCircle.layer.borderColor = accent.withAlphaComponent(0.30).cgColor

            glyphView.backgroundColor = .clear
            glyphView.layer.borderWidth = 1.6
            glyphView.layer.borderColor = accent.cgColor
            glyphView.layer.cornerRadius = ILMetrics.radiusGlyph

        case .offline:
            accent = UIColor(hex: "#6A655C")
            iconCircle.backgroundColor = accent.withAlphaComponent(alphaBg)
            iconCircle.layer.borderColor = accent.withAlphaComponent(0.30).cgColor

            glyphView.backgroundColor = .clear
            glyphView.layer.borderWidth = 1.6
            glyphView.layer.borderColor = accent.cgColor
            glyphView.layer.cornerRadius = 13.0
            glyphView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]

        case .done:
            accent = ILColors.green
            iconCircle.backgroundColor = accent.withAlphaComponent(alphaBg)
            iconCircle.layer.borderColor = accent.withAlphaComponent(0.30).cgColor

            glyphView.backgroundColor = accent
            glyphView.layer.borderWidth = 0
            glyphView.layer.cornerRadius = 13.0
        }
    }

    // `layer.borderColor` là CGColor tĩnh, không tự đảo theo trait — refresh thủ công
    // khi hệ thống đổi light/dark (ink giờ có biến thể dark).
    private func applyColorAppearanceChange() {
        updateAppearance()
    }
}
