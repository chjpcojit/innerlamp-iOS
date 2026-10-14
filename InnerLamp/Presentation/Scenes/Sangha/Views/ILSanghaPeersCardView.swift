//
//  ILSanghaPeersCardView.swift
//  InnerLamp
//

import UIKit

/// Thẻ số Phật tử cùng chùa: 3 vòng tròn chồng nhau (trang trí, không lộ danh tính) + câu mô tả.
final class ILSanghaPeersCardView: UIView {

    private lazy var label: UILabel = {
        let label = UILabel()
        label.font = ILTypography.bodySmall
        label.textColor = ILColors.inkSecondary
        label.numberOfLines = 0
        return label
    }()

    private var avatarCircles: [UIView] = []

    init() {
        super.init(frame: .zero)
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardRegular
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor

        let avatars = UIView()
        avatars.translatesAutoresizingMaskIntoConstraints = false
        let size: CGFloat = 26
        let overlap: CGFloat = 8
        var previous: UIView?
        for color in [ILColors.tint, ILColors.tint2, ILColors.tint3] {
            let circle = UIView()
            circle.backgroundColor = color
            circle.layer.cornerRadius = size / 2
            circle.layer.borderWidth = 1.5
            circle.layer.borderColor = ILColors.surface.cgColor
            circle.translatesAutoresizingMaskIntoConstraints = false
            avatars.addSubview(circle)
            avatarCircles.append(circle)
            NSLayoutConstraint.activate([
                circle.widthAnchor.constraint(equalToConstant: size),
                circle.heightAnchor.constraint(equalToConstant: size),
                circle.topAnchor.constraint(equalTo: avatars.topAnchor),
                circle.bottomAnchor.constraint(equalTo: avatars.bottomAnchor),
                circle.leadingAnchor.constraint(
                    equalTo: previous?.trailingAnchor ?? avatars.leadingAnchor,
                    constant: previous == nil ? 0 : -overlap
                )
            ])
            previous = circle
        }
        previous?.trailingAnchor.constraint(equalTo: avatars.trailingAnchor).isActive = true
        avatars.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [avatars, label])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = ILMetrics.spaceMedium - 2
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor, constant: ILMetrics.spaceMedium),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -ILMetrics.spaceMedium),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.spaceStandard),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.spaceStandard)
        ])

        // `layer.borderColor` là CGColor tĩnh — refresh thủ công khi đổi light/dark.
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.layer.borderColor = ILColors.border.cgColor
            self.avatarCircles.forEach { $0.layer.borderColor = ILColors.surface.cgColor }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(text: String) {
        label.text = text
    }
}
