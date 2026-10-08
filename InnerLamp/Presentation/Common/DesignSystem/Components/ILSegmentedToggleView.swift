//
//  ILSegmentedToggleView.swift
//  InnerLamp
//

import UIKit

/// Pill-shaped segmented toggle (design handoff "Âm lịch / Dương lịch"): a tinted track with the
/// selected segment raised as a surface pill. Generic over plain titles; selection is driven by
/// the owner (set `selectedIndex`, listen to `onSelect`).
public final class ILSegmentedToggleView: UIView {

    // MARK: - Properties
    public var titles: [String] = [] {
        didSet { rebuildSegments() }
    }

    public var selectedIndex: Int = 0 {
        didSet { if selectedIndex != oldValue { updateSelection() } }
    }

    public var onSelect: ((Int) -> Void)?

    // MARK: - UI Elements
    private let stack = UIStackView()
    private var buttons: [UIButton] = []

    // MARK: - Initializer
    public init(titles: [String] = []) {
        super.init(frame: .zero)
        setupViews()
        self.titles = titles
        rebuildSegments()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.segmentedTrack
        layer.cornerRadius = ILMetrics.radiusPill

        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Self.trackHeight),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: Self.inset),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Self.inset),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.inset),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.inset)
        ])
    }

    private func rebuildSegments() {
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        buttons = titles.enumerated().map { index, title in
            var configuration = UIButton.Configuration.plain()
            configuration.title = title
            configuration.background.cornerRadius = ILMetrics.radiusPill
            let button = UIButton(configuration: configuration)
            button.tag = index
            button.addTarget(self, action: #selector(handleTap(_:)), for: .touchUpInside)
            stack.addArrangedSubview(button)
            return button
        }
        updateSelection()
    }

    private func updateSelection() {
        for (index, button) in buttons.enumerated() {
            let isSelected = index == selectedIndex
            var configuration = button.configuration ?? .plain()
            configuration.background.backgroundColor = isSelected ? ILColors.surface : .clear
            configuration.baseForegroundColor = isSelected ? ILColors.ink : ILColors.inkSubtle
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
                var attributes = attributes
                attributes.font = ILTypography.chip
                return attributes
            }
            button.configuration = configuration
            if isSelected {
                ILMetrics.shadowSegmentSelected.apply(to: button.layer)
            } else {
                button.layer.shadowOpacity = 0
            }
            button.accessibilityTraits = isSelected ? [.button, .selected] : .button
        }
    }

    @objc private func handleTap(_ sender: UIButton) {
        guard sender.tag != selectedIndex else { return }
        selectedIndex = sender.tag
        onSelect?(sender.tag)
    }

    private static let trackHeight: CGFloat = 42
    private static let inset: CGFloat = 3
}
