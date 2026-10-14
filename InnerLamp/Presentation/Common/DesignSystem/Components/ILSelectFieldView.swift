//
//  ILSelectFieldView.swift
//  InnerLamp
//

import UIKit

/// Labelled "tap to choose" field (design handoff `IL-AddressPicker` field row): same caption and
/// card as `ILField`, but the card shows the current choice (or a placeholder) and a chevron, and
/// tapping it calls `onTap` so the owner can present a picker. It never edits text itself.
public final class ILSelectFieldView: UIView {

    public enum State {
        case normal
        case error
        case disabled
    }

    // MARK: - Properties
    public var value: String = "" {
        didSet { if value != oldValue { updateAppearance() } }
    }

    public var placeholder: String = "" {
        didSet { if placeholder != oldValue { updateAppearance() } }
    }

    public var fieldState: State = .normal {
        didSet { updateAppearance() }
    }

    public var onTap: (() -> Void)?

    // MARK: - UI Elements
    private let captionLabel = UILabel()
    private let container = UIView()
    private let valueLabel = UILabel()
    private let chevronView = UIImageView(image: ILIcons.chevronDown)

    // MARK: - Initializer
    public init(label: String, placeholder: String) {
        self.placeholder = placeholder
        super.init(frame: .zero)
        captionLabel.text = label.uppercased()
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        captionLabel.font = ILTypography.label
        captionLabel.textColor = ILColors.ink.withAlphaComponent(0.48)

        container.translatesAutoresizingMaskIntoConstraints = false
        container.layer.cornerRadius = ILMetrics.radiusInput
        container.layer.borderWidth = 1
        container.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))

        valueLabel.font = ILTypography.bodyLarge
        valueLabel.lineBreakMode = .byTruncatingTail

        chevronView.contentMode = .scaleAspectFit
        chevronView.tintColor = ILColors.ink.withAlphaComponent(0.42)
        chevronView.setContentHuggingPriority(.required, for: .horizontal)

        let content = UIStackView(arrangedSubviews: [valueLabel, chevronView])
        content.axis = .horizontal
        content.spacing = 10
        content.alignment = .center
        content.isUserInteractionEnabled = false
        content.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(content)

        let stack = UIStackView(arrangedSubviews: [captionLabel, container])
        stack.axis = .vertical
        stack.spacing = 7
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: ILMetrics.inputHeight),
            content.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            content.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            chevronView.widthAnchor.constraint(equalToConstant: 16),
            chevronView.heightAnchor.constraint(equalToConstant: 16),

            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        isAccessibilityElement = true
        accessibilityTraits = .button
        updateAppearance()

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILSelectFieldView, _) in
            view.updateAppearance()
        }
    }

    private func updateAppearance() {
        let hasValue = !value.isEmpty
        valueLabel.text = hasValue ? value : placeholder
        valueLabel.textColor = hasValue ? ILColors.ink : ILColors.ink.withAlphaComponent(0.42)

        switch fieldState {
        case .disabled:
            container.backgroundColor = ILColors.ink.withAlphaComponent(0.035)
            container.layer.borderColor = ILColors.ink.withAlphaComponent(0.07).cgColor
            container.alpha = 0.55
        case .error:
            container.backgroundColor = ILColors.surface
            container.layer.borderColor = ILColors.rose.cgColor
            container.alpha = 1
        case .normal:
            container.backgroundColor = ILColors.surface
            container.layer.borderColor = ILColors.ink.withAlphaComponent(0.12).cgColor
            container.alpha = 1
        }

        accessibilityLabel = captionLabel.text
        accessibilityValue = valueLabel.text
    }

    // MARK: - Actions
    @objc private func handleTap() {
        guard fieldState != .disabled else { return }
        onTap?()
    }
}
