//
//  ILFestivalsHostChipView.swift
//  InnerLamp
//

import UIKit

/// Chip chùa tổ chức trong 1 thẻ ngày lễ — pill nền `sunk2`, chạm mở Trang chùa. Riêng cho màn
/// "Lịch lễ Phật giáo" nên nằm ở `Scenes/Festivals`.
final class ILFestivalsHostChipView: UIControl {

    /// Pill height (`padding: 5px 10px` around an 11pt label) — shared with the "+N chùa" label.
    static let height: CGFloat = 28

    var onTap: (() -> Void)?

    private let titleLabel = UILabel()

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        layer.cornerRadius = ILMetrics.radiusPill
        backgroundColor = ILColors.sunk2

        titleLabel.font = ILTypography.label
        titleLabel.textColor = ILColors.ink
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Self.height),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
        ])

        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    @objc private func handleTouchDown() {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }
    }

    @objc private func handleTouchUp() {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = .identity
        }
    }

    @objc private func handleTap() {
        onTap?()
    }
}
