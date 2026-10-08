//
//  ILChipScrollView.swift
//  InnerLamp
//

import UIKit

/// Horizontally scrolling single-select row of `ILChip`s. Generic: callers pass titles and the
/// selected index; taps come back as the chip index.
public final class ILChipScrollView: UIView {

    // MARK: - Properties
    public var onSelect: ((Int) -> Void)?

    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private var chips: [ILChip] = []

    // MARK: - Initializer
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        stack.axis = .horizontal
        stack.spacing = ILMetrics.spaceSmall - 2
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: ILMetrics.screenHorizontal),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            stack.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }

    // MARK: - Configure
    public func configure(titles: [String], selectedIndex: Int) {
        if chips.count != titles.count {
            chips.forEach { $0.removeFromSuperview() }
            chips = titles.enumerated().map { index, title in
                let chip = ILChip(label: title)
                chip.onTap = { [weak self] in self?.onSelect?(index) }
                stack.addArrangedSubview(chip)
                return chip
            }
        }
        for (index, chip) in chips.enumerated() {
            chip.label = titles[index]
            chip.chipState = index == selectedIndex ? .selected : .normal
        }
    }
}
