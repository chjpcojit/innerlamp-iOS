//
//  ILMemorialChipGroupView.swift
//  InnerLamp
//

import UIKit

/// Single-choice chip group of the form (relationship, reminder lead time, reminder hour): wraps
/// `ILChip`s in an `ILChipFlowView`. Chips are only rebuilt when the option titles change, so a
/// selection change never resets layout.
final class ILMemorialChipGroupView: UIView {

    // MARK: - Properties
    var onSelect: ((Int) -> Void)?

    private var titles: [String] = []
    private var ids: [Int] = []
    private var chips: [ILChip] = []

    // MARK: - UI Elements
    private lazy var flowView: ILChipFlowView = {
        let view = ILChipFlowView(rowSpacing: ILMetrics.spaceSmall, itemSpacing: ILMetrics.spaceSmall)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        addSubview(flowView)
        NSLayoutConstraint.activate([
            flowView.topAnchor.constraint(equalTo: topAnchor),
            flowView.bottomAnchor.constraint(equalTo: bottomAnchor),
            flowView.leadingAnchor.constraint(equalTo: leadingAnchor),
            flowView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public API
    func configure(options: [ILMemorialOptionModel]) {
        let newTitles = options.map(\.title)
        let newIDs = options.map(\.id)
        if newTitles != titles || newIDs != ids {
            titles = newTitles
            ids = newIDs
            chips = options.map { option in
                let chip = ILChip(label: option.title)
                chip.onTap = { [weak self] in self?.onSelect?(option.id) }
                return chip
            }
            flowView.setItems(chips)
        }
        for (chip, option) in zip(chips, options) {
            chip.chipState = option.isSelected ? .selected : .normal
        }
    }
}
