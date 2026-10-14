//
//  ILDonateAmountGridView.swift
//  InnerLamp
//

import UIKit

/// 3-column grid of amount options ("20.000₫" … "Tùy tâm"). Tapping a cell reports its index.
final class ILDonateAmountGridView: UIView {

    private enum Layout {
        static let columns = 3
        static let cellHeight: CGFloat = 48
    }

    var onSelect: ((Int) -> Void)?

    private var options: [ILDonateStateModel.AmountOption] = []
    private var cells: [UIButton] = []
    private lazy var rowsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = ILMetrics.spaceSmall
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(rowsStack)
        NSLayoutConstraint.activate([
            rowsStack.topAnchor.constraint(equalTo: topAnchor),
            rowsStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            rowsStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            rowsStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(options newOptions: [ILDonateStateModel.AmountOption]) {
        guard newOptions != options else { return }
        let countChanged = newOptions.count != options.count
        options = newOptions
        if countChanged { rebuildCells() }
        for (index, option) in newOptions.enumerated() where index < cells.count {
            apply(option, to: cells[index])
        }
    }

    private func rebuildCells() {
        rowsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        cells = options.indices.map { index in
            let button = UIButton(type: .custom)
            button.titleLabel?.font = ILTypography.bodyMedium
            button.layer.cornerRadius = ILMetrics.radiusInput
            button.layer.borderWidth = 1
            button.heightAnchor.constraint(equalToConstant: Layout.cellHeight).isActive = true
            button.addAction(UIAction { [weak self] _ in self?.onSelect?(index) }, for: .touchUpInside)
            return button
        }
        for start in stride(from: 0, to: cells.count, by: Layout.columns) {
            let row = UIStackView(arrangedSubviews: Array(cells[start..<min(start + Layout.columns, cells.count)]))
            row.axis = .horizontal
            row.distribution = .fillEqually
            row.spacing = ILMetrics.spaceSmall
            rowsStack.addArrangedSubview(row)
        }
    }

    private func apply(_ option: ILDonateStateModel.AmountOption, to button: UIButton) {
        button.setTitle(option.title, for: .normal)
        button.setTitleColor(ILColors.medInk, for: .normal)
        button.backgroundColor = option.isSelected ? ILColors.medGoldTint : ILColors.medTrackSubtle
        button.layer.borderColor = (option.isSelected ? ILColors.medGoldTintBorder : ILColors.medTrack).cgColor
        button.accessibilityTraits = option.isSelected ? [.button, .selected] : .button
    }
}
