//
//  ILFamilyTreeChipRowView.swift
//  InnerLamp
//

import UIKit

/// Horizontally scrolling single-select row of tree-palette generation chips (selected: brown fill
/// with cream text; unselected: translucent cream with brown text and border). Taps come back as
/// the chip index.
final class ILFamilyTreeChipRowView: UIView {

    private typealias Tree = ILColors.FamilyTree
    private typealias Metrics = ILMetrics.FamilyTree

    // MARK: - Properties
    var onSelect: ((Int) -> Void)?

    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.alwaysBounceHorizontal = true
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()

    private lazy var stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = ILMetrics.spaceSmall - 2
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private var chips: [ChipControl] = []

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        addSubview(scrollView)
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: Metrics.headerInset),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -Metrics.headerInset),
            stack.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }

    // MARK: - Configure
    func configure(titles: [String], selectedIndex: Int) {
        if chips.count != titles.count {
            chips.forEach { $0.removeFromSuperview() }
            chips = titles.indices.map { index in
                let chip = ChipControl()
                chip.onTap = { [weak self] in self?.onSelect?(index) }
                stack.addArrangedSubview(chip)
                return chip
            }
        }
        for (index, chip) in chips.enumerated() {
            chip.title = titles[index]
            chip.setSelectedStyle(index == selectedIndex)
        }
    }
}

// MARK: - Chip
private extension ILFamilyTreeChipRowView {

    final class ChipControl: UIControl {
        var onTap: (() -> Void)?

        var title: String = "" {
            didSet { label.text = title }
        }

        private lazy var label: UILabel = {
            let label = UILabel()
            label.font = ILTypography.treeChip
            label.isUserInteractionEnabled = false
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)
            layer.cornerRadius = Metrics.chipHeight / 2
            layer.borderWidth = 1
            accessibilityTraits = .button
            addSubview(label)
            NSLayoutConstraint.activate([
                heightAnchor.constraint(equalToConstant: Metrics.chipHeight),
                label.centerYAnchor.constraint(equalTo: centerYAnchor),
                label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Metrics.chipPaddingH),
                label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Metrics.chipPaddingH)
            ])
            addTarget(self, action: #selector(handleTap), for: .touchUpInside)
            setSelectedStyle(false)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var isHighlighted: Bool {
            didSet { alpha = isHighlighted ? 0.7 : 1 }
        }

        func setSelectedStyle(_ isSelected: Bool) {
            let apply = {
                self.backgroundColor = isSelected ? Tree.brown : Tree.chipSurface
                self.label.textColor = isSelected ? Tree.cream : Tree.bark
                self.layer.borderColor = (isSelected ? Tree.brown : Tree.border).cgColor
            }
            accessibilityTraits = isSelected ? [.button, .selected] : .button
            if window != nil {
                UIView.animate(withDuration: 0.18, animations: apply)
            } else {
                apply()
            }
        }

        @objc private func handleTap() { onTap?() }
    }
}
