//
//  ILMeditationSetupTipView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import UIKit

/// Thẻ nhắc nhỏ (nền vàng nhạt) dưới nhóm CHUÔNG — biểu tượng ngọn lửa trong vòng tròn + dòng gợi
/// ý tư thế ngồi. Composition riêng của màn Chuẩn bị thiền (nội dung + vòng lửa vàng là đặc thù
/// màn này), nên nằm feature-scoped.
final class ILMeditationSetupTipView: UIView {

    // MARK: - Properties
    var text: String = "" {
        didSet { textLabel.text = text }
    }

    // MARK: - UI Elements
    private lazy var flameView = ILFlameView(height: 10, topColor: ILColors.goldBright)

    private let flameBadge = UIView()

    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.link
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
        applyDynamicColors()
        registerForAppearanceChanges()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.gold.withAlphaComponent(0.12)
        layer.cornerRadius = 16

        flameBadge.translatesAutoresizingMaskIntoConstraints = false
        flameBadge.layer.cornerRadius = 13
        flameBadge.layer.borderWidth = 1
        addSubview(flameBadge)

        flameView.translatesAutoresizingMaskIntoConstraints = false
        flameBadge.addSubview(flameView)

        textLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textLabel)

        NSLayoutConstraint.activate([
            flameBadge.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            flameBadge.centerYAnchor.constraint(equalTo: centerYAnchor),
            flameBadge.widthAnchor.constraint(equalToConstant: 26),
            flameBadge.heightAnchor.constraint(equalToConstant: 26),

            flameView.centerXAnchor.constraint(equalTo: flameBadge.centerXAnchor),
            flameView.centerYAnchor.constraint(equalTo: flameBadge.centerYAnchor),

            textLabel.leadingAnchor.constraint(equalTo: flameBadge.trailingAnchor, constant: 12),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            textLabel.topAnchor.constraint(equalTo: topAnchor, constant: 13),
            textLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -13)
        ])
    }

    private func applyDynamicColors() {
        flameBadge.layer.borderColor = ILColors.goldBorder.cgColor
    }

    private func registerForAppearanceChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.applyDynamicColors()
        }
    }
}
