//
//  ILPhotoViewerIconButton.swift
//  InnerLamp
//

import UIKit

/// Nút tròn chứa 1 icon template trên nền tối của viewer (×, tim, ‹ ›). `backdrop` bật nền mờ cho
/// nút nổi trên ảnh (mũi tên trước/sau).
final class ILPhotoViewerIconButton: UIControl {

    private let iconView = UIImageView()
    private let diameter: CGFloat

    var icon: UIImage? {
        didSet { iconView.image = icon }
    }

    init(icon: UIImage, diameter: CGFloat, backdrop: Bool, accessibilityLabel: String) {
        self.diameter = diameter
        super.init(frame: .zero)
        isAccessibilityElement = true
        accessibilityTraits = .button
        self.accessibilityLabel = accessibilityLabel

        iconView.image = icon
        iconView.tintColor = ILColors.inkOnDark
        iconView.contentMode = .scaleAspectFit
        iconView.isUserInteractionEnabled = false
        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)

        if backdrop {
            backgroundColor = ILColors.darkBackground.withAlphaComponent(0.55)
            layer.cornerRadius = diameter / 2
        }

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: diameter),
            heightAnchor.constraint(equalToConstant: diameter),
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.45),
            iconView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.45)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.6 : 1 }
    }
}
