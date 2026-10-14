//
//  ILLampKindPickerView.swift
//  InnerLamp
//

import UIKit

/// Three equal-width cards — one per lamp kind — with the lamp artwork above its name. The
/// selected card gets a gold border (design handoff `offer`, "Loại đèn").
final class ILLampKindPickerView: UIView {

    var onSelect: ((ILLampKind) -> Void)?

    private lazy var stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = ILMetrics.rowSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private var cards: [ILLampKind: KindCard] = [:]

    init() {
        super.init(frame: .zero)
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        for kind in ILLampKind.allCases {
            let card = KindCard(kind: kind)
            card.onTap = { [weak self] in self?.onSelect?(kind) }
            cards[kind] = card
            stack.addArrangedSubview(card)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(options: [ILLightLampStateModel.KindOption]) {
        for option in options {
            cards[option.kind]?.configure(title: option.title, isSelected: option.isSelected)
        }
    }

    // MARK: - Card
    private final class KindCard: UIControl {

        var onTap: (() -> Void)?
        private let artView: ILLampArtView
        private lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.font = ILTypography.chip
            label.textColor = ILColors.ink
            label.textAlignment = .center
            return label
        }()

        init(kind: ILLampKind) {
            artView = ILLampArtView(kind: kind)
            super.init(frame: .zero)

            backgroundColor = ILColors.surface
            layer.cornerRadius = ILMetrics.Lamp.kindCardRadius
            layer.borderWidth = 1

            let size = ILMetrics.Lamp.kindPickerArtSize
            [artView, titleLabel].forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
                addSubview($0)
            }
            NSLayoutConstraint.activate([
                artView.topAnchor.constraint(equalTo: topAnchor, constant: ILMetrics.spaceMedium - 2),
                artView.centerXAnchor.constraint(equalTo: centerXAnchor),
                artView.widthAnchor.constraint(equalToConstant: size),
                artView.heightAnchor.constraint(equalToConstant: size * ILMetrics.Lamp.artHeightRatio),
                titleLabel.topAnchor.constraint(equalTo: artView.bottomAnchor, constant: 6),
                titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
                titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
                titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
            ])
            addTarget(self, action: #selector(handleTap), for: .touchUpInside)
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: KindCard, _) in
                view.applyBorder(isSelected: view.isSelected)
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func configure(title: String, isSelected: Bool) {
            titleLabel.text = title
            self.isSelected = isSelected
            applyBorder(isSelected: isSelected)
            accessibilityLabel = title
            accessibilityTraits = isSelected ? [.button, .selected] : .button
        }

        private func applyBorder(isSelected: Bool) {
            layer.borderColor = (isSelected ? ILColors.gold : ILColors.border).cgColor
        }

        @objc private func handleTap() {
            onTap?()
        }
    }
}
