//
//  ILPlayerOptionRowView.swift
//  InnerLamp
//

import UIKit

/// A row of equal-width selectable segments for the full-screen player (playback speed / sleep
/// timer) — 38pt tall, 12pt corner radius, one selection at a time. Selected segment fills the
/// `--il-th-ink` background with `--il-canvas` text; unselected uses the translucent `--il-pl-chip`
/// surface. Feature-scoped because the palette is the player's immersive theme, distinct from
/// `ILMeditationSetupDurationView` (52pt, solid `surface`) and `ILChip` (pill).
final class ILPlayerOptionRowView: UIControl {

    // MARK: - Properties
    /// The labels of each option, in display order.
    var options: [String] = [] {
        didSet {
            guard options != oldValue else { return }
            rebuild()
        }
    }

    var selectedIndex: Int = 0 {
        didSet { updateSelection() }
    }

    /// Fires the index of the option just selected.
    var onSelect: ((Int) -> Void)?

    // MARK: - UI Elements
    private let stack = UIStackView()
    private var buttons: [OptionButton] = []

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = ILMetrics.spaceSmall
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 38),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func rebuild() {
        buttons.forEach { $0.removeFromSuperview() }
        buttons = options.enumerated().map { index, label in
            let button = OptionButton()
            button.title = label
            button.onTap = { [weak self] in
                guard let self else { return }
                self.selectedIndex = index
                self.onSelect?(index)
            }
            return button
        }
        buttons.forEach { stack.addArrangedSubview($0) }
        updateSelection()
    }

    private func updateSelection() {
        for (index, button) in buttons.enumerated() {
            button.isOn = index == selectedIndex
        }
    }
}

// MARK: - OptionButton
private final class OptionButton: UIControl {

    var title: String = "" {
        didSet { titleLabel.text = title }
    }

    var isOn: Bool = false {
        didSet { updateAppearance() }
    }

    var onTap: (() -> Void)?

    private let titleLabel = UILabel()

    init() {
        super.init(frame: .zero)
        titleLabel.font = ILTypography.chip
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        layer.cornerRadius = 12
        layer.borderWidth = 1

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        updateAppearance()

        // `layer.borderColor` is a static CGColor — refresh manually when light/dark flips.
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.updateAppearance()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateAppearance() {
        if isOn {
            backgroundColor = ILColors.templeHeaderInk
            titleLabel.textColor = ILColors.canvas
            layer.borderColor = ILColors.templeHeaderInk.cgColor
        } else {
            backgroundColor = ILColors.playerChipBackground
            titleLabel.textColor = ILColors.playerChipText
            layer.borderColor = UIColor.clear.cgColor
        }
    }

    @objc private func handleTap() {
        onTap?()
    }
}
