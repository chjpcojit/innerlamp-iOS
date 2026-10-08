//
//  ILSwitchRowView.swift
//  InnerLamp
//

import UIKit

/// Plain "title + subtitle + switch" row (design handoff reminder card). Unlike `ILToggleCardRow`
/// it has no icon tile and no card chrome, so it can sit inside a larger card.
public final class ILSwitchRowView: UIView {

    // MARK: - Properties
    public var isOn: Bool {
        get { switchControl.isOn }
        set { if switchControl.isOn != newValue { switchControl.setOn(newValue, animated: false) } }
    }

    public var onToggle: ((Bool) -> Void)?

    // MARK: - UI Elements
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let switchControl = UISwitch()

    // MARK: - Initializer
    public init(title: String, subtitle: String = "", isOn: Bool = false) {
        super.init(frame: .zero)
        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle.isEmpty
        switchControl.isOn = isOn
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        titleLabel.font = ILTypography.bodyMedium
        titleLabel.textColor = ILColors.ink
        titleLabel.numberOfLines = 0

        subtitleLabel.font = ILTypography.subhead
        subtitleLabel.textColor = ILColors.inkSubtle
        subtitleLabel.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        switchControl.onTintColor = ILColors.gold
        switchControl.setContentHuggingPriority(.required, for: .horizontal)
        switchControl.addTarget(self, action: #selector(handleValueChanged), for: .valueChanged)

        let row = UIStackView(arrangedSubviews: [textStack, switchControl])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = ILMetrics.spaceMedium
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor),
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    @objc private func handleValueChanged() {
        onToggle?(switchControl.isOn)
    }
}
