//
//  ILAvatarView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 11/9/26.
//

import UIKit

public final class ILAvatarView: UIView {
    
    // MARK: - Properties
    public var initials: String = "DT" {
        didSet { initialsLabel.text = initials }
    }
    
    public var tone: ILColors.Tone = .gold {
        didSet { updateAppearance() }
    }
    
    public var size: CGFloat = 40.0 {
        didSet {
            updateSizeConstraints()
            updateAppearance()
        }
    }
    
    // MARK: - UI Elements
    private let initialsLabel = UILabel()
    private var widthConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?
    
    // MARK: - Initializer
    public init(
        initials: String = "DT",
        tone: ILColors.Tone = .gold,
        size: CGFloat = 40.0
    ) {
        self.initials = initials
        self.tone = tone
        self.size = size
        super.init(frame: .zero)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.borderWidth = 1
        clipsToBounds = true
        
        initialsLabel.translatesAutoresizingMaskIntoConstraints = false
        initialsLabel.textAlignment = .center
        initialsLabel.text = initials
        
        addSubview(initialsLabel)
        
        widthConstraint = widthAnchor.constraint(equalToConstant: size)
        heightConstraint = heightAnchor.constraint(equalToConstant: size)
        
        NSLayoutConstraint.activate([
            widthConstraint!,
            heightConstraint!,
            initialsLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        updateAppearance()
    }
    
    private func updateSizeConstraints() {
        widthConstraint?.constant = size
        heightConstraint?.constant = size
        layer.cornerRadius = size / 2.0
    }
    
    private func updateAppearance() {
        layer.cornerRadius = size / 2.0
        
        backgroundColor = tone.avatarBackground
        layer.borderColor = tone.avatarBorder.cgColor
        initialsLabel.textColor = tone.textColor
        
        let fontSize = max(10, round(size * 0.34))
        initialsLabel.font = ILTypography.beVietnamPro(size: fontSize, weight: .medium)
    }
}
