//
//  ILSanghaPillButton.swift
//  InnerLamp
//

import UIKit

/// Nút pill 32pt của tab Chùa ("Nhắc tôi" / "Đã nhắc" / "Giữ chỗ" / "Đã giữ chỗ" / "Chọn").
/// Tắt: viền xám, chữ `ink`. Bật kiểu vàng: nền vàng nhạt, chữ `link`. Bật kiểu đặc: nền `ink`.
final class ILSanghaPillButton: UIButton {

    enum Style {
        case off
        case onGold
        case onSolid
    }

    private var style: Style = .off

    init() {
        super.init(frame: .zero)
        titleLabel?.font = ILTypography.subheadMedium
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 13, bottom: 0, right: 13)
        layer.cornerRadius = ILMetrics.radiusPill
        layer.borderWidth = 1
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        heightAnchor.constraint(equalToConstant: 32).isActive = true
        apply(style: .off)

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.apply(style: self.style)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, style: Style) {
        setTitle(title, for: .normal)
        apply(style: style)
    }

    private func apply(style: Style) {
        self.style = style
        switch style {
        case .off:
            backgroundColor = .clear
            layer.borderColor = ILColors.borderStrong.cgColor
            setTitleColor(ILColors.ink, for: .normal)
        case .onGold:
            backgroundColor = ILColors.gold.withAlphaComponent(0.14)
            layer.borderColor = ILColors.gold.withAlphaComponent(0.45).cgColor
            setTitleColor(ILColors.link, for: .normal)
        case .onSolid:
            backgroundColor = ILColors.ink
            layer.borderColor = ILColors.ink.cgColor
            setTitleColor(ILColors.canvas, for: .normal)
        }
    }
}
