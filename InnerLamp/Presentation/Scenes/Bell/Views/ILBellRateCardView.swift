//
//  ILBellRateCardView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import UIKit

/// The rhythm/interval card at the bottom of the "Chuông mõ" screen: a label + value with −/+
/// steppers, and (in mo + bell mode) a "ring bell after every" chip row. Feature-scoped — its
/// composition is specific to this screen.
final class ILBellRateCardView: UIView {

    // MARK: - Properties
    var rateLabelText: String = "" {
        didSet { rateLabel.text = rateLabelText }
    }

    var rateValueText: String = "" {
        didSet { rateValueLabel.text = rateValueText }
    }

    var everyPromptText: String = "" {
        didSet { everyPromptLabel.text = everyPromptText }
    }

    var everyLabels: [String] = [] {
        didSet { rebuildEveryChips() }
    }

    var selectedEveryIndex: Int = 0 {
        didSet { updateEverySelection() }
    }

    var showEveryRow: Bool = false {
        didSet { everyRow.isHidden = !showEveryRow }
    }

    var onSlower: (() -> Void)?
    var onFaster: (() -> Void)?
    var onEverySelected: ((Int) -> Void)?

    // MARK: - UI Elements
    private let rateLabel = UILabel()
    private let rateValueLabel = UILabel()
    private let slowerButton = ILBellStepperButton(symbol: "−")
    private let fasterButton = ILBellStepperButton(symbol: "+")

    private let divider = UIView()
    private let everyRow = UIStackView()
    private let everyPromptLabel = UILabel()
    private let everyChipsStack = UIStackView()
    private var everyChips: [ILBellChipView] = []

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.medCard
        layer.cornerRadius = ILMetrics.radiusCardMedium
        layer.borderWidth = 1
        layer.borderColor = ILColors.medTrack.cgColor

        rateLabel.font = ILTypography.subhead
        rateLabel.textColor = ILColors.medInkSecondary

        rateValueLabel.font = ILTypography.bellRateValue
        rateValueLabel.textColor = ILColors.medInk

        let textStack = UIStackView(arrangedSubviews: [rateLabel, rateValueLabel])
        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.translatesAutoresizingMaskIntoConstraints = false

        slowerButton.onTap = { [weak self] in self?.onSlower?() }
        fasterButton.onTap = { [weak self] in self?.onFaster?() }

        let topRow = UIStackView(arrangedSubviews: [textStack, slowerButton, fasterButton])
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.spacing = ILMetrics.spaceMedium
        topRow.translatesAutoresizingMaskIntoConstraints = false

        divider.backgroundColor = ILColors.medTrack
        divider.translatesAutoresizingMaskIntoConstraints = false

        everyPromptLabel.font = ILTypography.subhead
        everyPromptLabel.textColor = ILColors.medInkSecondary
        everyPromptLabel.setContentHuggingPriority(.required, for: .horizontal)

        everyChipsStack.axis = .horizontal
        everyChipsStack.alignment = .center
        everyChipsStack.spacing = 6

        everyRow.axis = .horizontal
        everyRow.alignment = .center
        everyRow.spacing = ILMetrics.spaceSmall
        everyRow.addArrangedSubview(everyPromptLabel)
        everyRow.addArrangedSubview(everyChipsStack)
        everyRow.translatesAutoresizingMaskIntoConstraints = false

        addSubview(topRow)
        addSubview(divider)
        addSubview(everyRow)

        NSLayoutConstraint.activate([
            topRow.topAnchor.constraint(equalTo: topAnchor, constant: ILMetrics.spaceMedium),
            topRow.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.spaceStandard),
            topRow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.spaceStandard),

            slowerButton.widthAnchor.constraint(equalToConstant: 40),
            slowerButton.heightAnchor.constraint(equalToConstant: 40),
            fasterButton.widthAnchor.constraint(equalToConstant: 40),
            fasterButton.heightAnchor.constraint(equalToConstant: 40),

            divider.topAnchor.constraint(equalTo: topRow.bottomAnchor, constant: ILMetrics.spaceMedium),
            divider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.spaceStandard),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.spaceStandard),
            divider.heightAnchor.constraint(equalToConstant: 1),

            everyRow.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: ILMetrics.spaceMedium),
            everyRow.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.spaceStandard),
            everyRow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.spaceStandard),
            everyRow.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -ILMetrics.spaceMedium)
        ])
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILBellRateCardView, _) in
            view.applyColorAppearanceChange()
        }
    }

    private func rebuildEveryChips() {
        everyChips.forEach { $0.removeFromSuperview() }
        everyChips = everyLabels.enumerated().map { index, label in
            let chip = ILBellChipView(label: label, font: ILTypography.subheadMedium, horizontalPadding: 9)
            chip.onTap = { [weak self] in self?.onEverySelected?(index) }
            return chip
        }
        everyChips.forEach { everyChipsStack.addArrangedSubview($0) }
        updateEverySelection()
    }

    private func updateEverySelection() {
        for (index, chip) in everyChips.enumerated() {
            chip.isOn = index == selectedEveryIndex
        }
    }

    private func applyColorAppearanceChange() {
        layer.borderColor = ILColors.medTrack.cgColor
        divider.backgroundColor = ILColors.medTrack
    }
}

// MARK: - Stepper button (− / +)
private final class ILBellStepperButton: UIControl {

    var onTap: (() -> Void)?

    private let symbolLabel = UILabel()

    init(symbol: String) {
        super.init(frame: .zero)
        layer.cornerRadius = 20
        layer.borderWidth = 1
        layer.borderColor = ILColors.medBorder.cgColor

        symbolLabel.font = ILTypography.statValue
        symbolLabel.textColor = ILColors.medInk
        symbolLabel.text = symbol
        symbolLabel.textAlignment = .center
        symbolLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(symbolLabel)

        NSLayoutConstraint.activate([
            symbolLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            symbolLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILBellStepperButton, _) in
            view.applyColorAppearanceChange()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func applyColorAppearanceChange() {
        layer.borderColor = ILColors.medBorder.cgColor
    }

    @objc private func handleTap() {
        onTap?()
    }
}
