//
//  ILLanguageOptionRowView.swift
//  InnerLamp
//

import UIKit

/// One selectable language row: title + subtitle on the left, radio dot on the right. The whole
/// row is tappable; the selected row gets a gold border.
final class ILLanguageOptionRowView: UIControl {

    // MARK: - Properties
    var onTap: (() -> Void)?

    override var isSelected: Bool {
        didSet { updateAppearance() }
    }

    // MARK: - UI Elements
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.bodySmallMedium
        label.numberOfLines = 1
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.caption
        label.numberOfLines = 1
        return label
    }()

    private lazy var radioRing: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.layer.borderWidth = 1.5
        view.isUserInteractionEnabled = false
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var radioDot: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4.5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

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
        layer.cornerRadius = ILMetrics.radiusCardSmall
        layer.borderWidth = 1

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.isUserInteractionEnabled = false
        textStack.translatesAutoresizingMaskIntoConstraints = false

        radioRing.addSubview(radioDot)

        addSubview(textStack)
        addSubview(radioRing)

        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.spaceStandard),
            textStack.topAnchor.constraint(equalTo: topAnchor, constant: 15),
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -15),
            textStack.trailingAnchor.constraint(equalTo: radioRing.leadingAnchor, constant: -ILMetrics.spaceMedium),

            radioRing.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.spaceStandard),
            radioRing.centerYAnchor.constraint(equalTo: centerYAnchor),
            radioRing.widthAnchor.constraint(equalToConstant: 20),
            radioRing.heightAnchor.constraint(equalToConstant: 20),

            radioDot.centerXAnchor.constraint(equalTo: radioRing.centerXAnchor),
            radioDot.centerYAnchor.constraint(equalTo: radioRing.centerYAnchor),
            radioDot.widthAnchor.constraint(equalToConstant: 9),
            radioDot.heightAnchor.constraint(equalToConstant: 9)
        ])

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        accessibilityTraits = .button

        updateAppearance()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILLanguageOptionRowView, _) in
            view.updateAppearance()
        }
    }

    // MARK: - Configure
    func configure(title: String, subtitle: String, isSelected: Bool) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        self.isSelected = isSelected
        accessibilityLabel = title
    }

    // `CGColor` layer colors don't flip with the trait — refreshed manually on appearance change.
    private func updateAppearance() {
        backgroundColor = ILColors.surface
        titleLabel.textColor = ILColors.ink
        subtitleLabel.textColor = ILColors.inkMuted
        layer.borderColor = (isSelected ? ILColors.goldBorder : ILColors.border).cgColor
        radioRing.layer.borderColor = (isSelected ? ILColors.gold : ILColors.ink.withAlphaComponent(0.22)).cgColor
        radioDot.backgroundColor = isSelected ? ILColors.gold : .clear
        accessibilityTraits = isSelected ? [.button, .selected] : .button
    }

    @objc private func handleTap() {
        onTap?()
    }
}
