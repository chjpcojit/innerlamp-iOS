//
//  ILBellModeSegmentedView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import UIKit

/// Three-segment control (Mõ / Chuông / Mõ + chuông) for the "Chuông mõ" screen. Equal-width
/// segments inside a pill container, styled with the immersive `--il-med-*` palette. Feature-scoped
/// because the exact segmented pill look is specific to this screen.
final class ILBellModeSegmentedView: UIControl {

    // MARK: - Properties
    var labels: [String] = [] {
        didSet { rebuild() }
    }

    var selectedIndex: Int = 0 {
        didSet { updateSelection() }
    }

    var onSelect: ((Int) -> Void)?

    // MARK: - UI Elements
    private lazy var container: UIView = {
        let view = UIView()
        view.backgroundColor = ILColors.medTrackSubtle
        view.layer.cornerRadius = ILMetrics.radiusPill
        view.layer.borderWidth = 1
        view.layer.borderColor = ILColors.medTrack.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .fill
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    private var segmentViews: [SegmentButton] = []

    // MARK: - Initializer
    init(labels: [String] = []) {
        self.labels = labels
        super.init(frame: .zero)
        setupViews()
        rebuild()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        addSubview(container)

        container.addSubview(stack)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.heightAnchor.constraint(equalToConstant: 40),

            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 3),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -3),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 3),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -3)
        ])
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILBellModeSegmentedView, _) in
            view.applyColorAppearanceChange()
        }
    }

    private func rebuild() {
        segmentViews.forEach { $0.removeFromSuperview() }
        segmentViews = labels.enumerated().map { index, label in
            let button = SegmentButton()
            button.title = label
            button.onTap = { [weak self] in
                guard let self else { return }
                self.selectedIndex = index
                self.onSelect?(index)
            }
            return button
        }
        segmentViews.forEach { stack.addArrangedSubview($0) }
        updateSelection()
    }

    private func updateSelection() {
        for (index, view) in segmentViews.enumerated() {
            view.isOn = index == selectedIndex
        }
    }

    private func applyColorAppearanceChange() {
        container.layer.borderColor = ILColors.medTrack.cgColor
        segmentViews.forEach { $0.refresh() }
    }
}

// MARK: - SegmentButton
private final class SegmentButton: UIControl {

    var title: String = "" {
        didSet { titleLabel.text = title }
    }

    var isOn: Bool = false {
        didSet { refresh() }
    }

    var onTap: (() -> Void)?

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.bodySmallMedium
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    init() {
        super.init(frame: .zero)
        addSubview(titleLabel)

        layer.cornerRadius = ILMetrics.radiusPill

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        refresh()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refresh() {
        backgroundColor = isOn ? ILColors.medTrack : .clear
        titleLabel.textColor = isOn ? ILColors.medInk : ILColors.medInkSecondary
    }

    @objc private func handleTap() {
        onTap?()
    }
}
