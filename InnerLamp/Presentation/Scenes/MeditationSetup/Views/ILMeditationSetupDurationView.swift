//
//  ILMeditationSetupDurationView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import UIKit

/// Thanh chọn thời lượng cho màn Chuẩn bị thiền: các nút rộng đều nhau (52pt, bo 16pt), một lựa chọn.
/// Nút đang chọn đảo nền `ink` + chữ `canvas`; nút chưa chọn nền `surface` + chữ `ink` + viền mờ.
/// Feature-scoped vì kiểu dáng cụ thể (cao 52pt, chữ 16pt medium) là riêng của màn này, không phải
/// `ILChip` (pill 34pt) hay `ILBellModeSegmentedView` (palette immersive `--il-med-*`).
final class ILMeditationSetupDurationView: UIControl {

    // MARK: - Properties
    /// Các mức thời lượng (phút) — hiển thị dưới dạng số.
    var options: [Int] = [] {
        didSet {
            guard options != oldValue else { return }
            rebuild()
        }
    }

    var selectedIndex: Int = 0 {
        didSet { updateSelection() }
    }

    /// Bắn ra giá trị (phút) của mức vừa chọn.
    var onSelect: ((Int) -> Void)?

    // MARK: - UI Elements
    private let stack = UIStackView()
    private var buttons: [DurationButton] = []

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 52),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func rebuild() {
        buttons.forEach { $0.removeFromSuperview() }
        buttons = options.enumerated().map { index, minutes in
            let button = DurationButton()
            button.title = "\(minutes)"
            button.onTap = { [weak self] in
                guard let self else { return }
                self.selectedIndex = index
                self.onSelect?(minutes)
            }
            return button
        }
        buttons.forEach { stack.addArrangedSubview($0) }
        updateSelection()
    }

    private func updateSelection() {
        for (index, button) in buttons.enumerated() {
            button.isOn = index == selectedIndex
        }
    }
}

// MARK: - DurationButton
private final class DurationButton: UIControl {

    var title: String = "" {
        didSet { titleLabel.text = title }
    }

    var isOn: Bool = false {
        didSet { updateAppearance() }
    }

    var onTap: (() -> Void)?

    private let titleLabel = UILabel()

    init() {
        super.init(frame: .zero)
        titleLabel.font = ILTypography.optionChip
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        layer.cornerRadius = 16
        layer.borderWidth = 1

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        updateAppearance()

        // `layer.borderColor` là CGColor tĩnh, không tự đảo theo trait — refresh thủ công.
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.updateAppearance()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateAppearance() {
        if isOn {
            backgroundColor = ILColors.ink
            titleLabel.textColor = ILColors.canvas
            layer.borderColor = ILColors.ink.cgColor
        } else {
            backgroundColor = ILColors.surface
            titleLabel.textColor = ILColors.ink
            layer.borderColor = ILColors.ink.withAlphaComponent(0.14).cgColor
        }
    }

    @objc private func handleTap() {
        onTap?()
    }
}
