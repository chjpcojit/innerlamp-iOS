//
//  ILBellChipView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import UIKit

/// A selectable pill used by the "Chuông mõ" screen for the preset chips and the "ring bell after
/// every" options. Styled with the immersive `--il-med-*` palette (gold-tinted when selected,
/// transparent otherwise) — distinct from the light-surface `ILChip`, so it lives feature-scoped.
final class ILBellChipView: UIControl {

    // MARK: - Properties
    var label: String = "" {
        didSet { titleLabel.text = label }
    }

    var isOn: Bool = false {
        didSet { updateAppearance() }
    }

    var onTap: (() -> Void)?

    // MARK: - UI Elements
    private let titleLabel = UILabel()
    private let titleLabelHorizontalPadding: CGFloat

    // MARK: - Initializer
    init(label: String = "", font: UIFont = ILTypography.chip, horizontalPadding: CGFloat = 14) {
        self.label = label
        self.titleLabelHorizontalPadding = horizontalPadding
        super.init(frame: .zero)
        titleLabel.font = font
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        layer.cornerRadius = ILMetrics.radiusPill
        layer.borderWidth = 1

        titleLabel.text = label
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: titleLabelHorizontalPadding),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -titleLabelHorizontalPadding),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        updateAppearance()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILBellChipView, _) in
            view.applyColorAppearanceChange()
        }
    }

    private func updateAppearance() {
        if isOn {
            backgroundColor = ILColors.medGoldTint
            layer.borderColor = ILColors.medGoldChipBorder.cgColor
            titleLabel.textColor = ILColors.link
        } else {
            backgroundColor = .clear
            layer.borderColor = ILColors.medTrack.cgColor
            titleLabel.textColor = ILColors.medInkStrong
        }
    }

    private func applyColorAppearanceChange() {
        updateAppearance()
    }

    @objc private func handleTap() {
        onTap?()
    }
}
