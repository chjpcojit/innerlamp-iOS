//
//  ILSanghaPlaceholderView.swift
//  InnerLamp
//

import UIKit

/// Khối nền `sunk2` giữ chỗ cho bản đồ "Chùa gần bạn" (design dùng `image-slot` — chưa có bản đồ
/// thật).
final class ILSanghaPlaceholderView: UIView {

    init(text: String, height: CGFloat) {
        super.init(frame: .zero)
        backgroundColor = ILColors.sunk2
        layer.cornerRadius = ILMetrics.radiusCardRegular
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor
        clipsToBounds = true
        heightAnchor.constraint(equalToConstant: height).isActive = true

        let label = UILabel()
        label.font = ILTypography.note
        label.textColor = ILColors.inkMuted
        label.text = text
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.layer.borderColor = ILColors.border.cgColor
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
