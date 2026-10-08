//
//  ILReaderAutoScrollRowView.swift
//  InnerLamp
//

import UIKit

/// Row under the Reader header: a pill with the "Tự cuộn" toggle, the "Màn hình luôn sáng" note and
/// the tap hint ("Chạm để tạm dừng" / "Chạm để tiếp tục") pushed to the trailing edge.
final class ILReaderAutoScrollRowView: UIView {

    // MARK: - Properties
    var onToggle: (() -> Void)?

    // MARK: - UI Elements
    private let pillView = UIControl()
    private let switchContainer = UIView()
    private let switchControl = UISwitch()
    private let toggleLabel = UILabel()
    private let noteLabel = UILabel()
    private let hintLabel = UILabel()

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
        pillView.layer.cornerRadius = 15
        pillView.layer.borderWidth = 1
        pillView.addTarget(self, action: #selector(handleToggle), for: .touchUpInside)

        // The design toggle is 28×16pt; a `UISwitch` is 51×31pt, so scale it inside a fixed box.
        switchControl.onTintColor = ILColors.gold
        switchControl.transform = CGAffineTransform(scaleX: 28.0 / 51.0, y: 28.0 / 51.0)
        switchControl.isUserInteractionEnabled = false
        switchContainer.addSubview(switchControl)
        switchControl.translatesAutoresizingMaskIntoConstraints = false

        toggleLabel.font = ILTypography.subheadMedium
        noteLabel.font = ILTypography.label
        hintLabel.font = ILTypography.label
        hintLabel.textAlignment = .right
        hintLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let pillStack = UIStackView(arrangedSubviews: [switchContainer, toggleLabel])
        pillStack.axis = .horizontal
        pillStack.spacing = 8
        pillStack.alignment = .center
        pillStack.isUserInteractionEnabled = false
        pillStack.translatesAutoresizingMaskIntoConstraints = false
        pillView.addSubview(pillStack)

        let rowStack = UIStackView(arrangedSubviews: [pillView, noteLabel, hintLabel])
        rowStack.axis = .horizontal
        rowStack.spacing = 8
        rowStack.alignment = .center
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rowStack)

        NSLayoutConstraint.activate([
            switchContainer.widthAnchor.constraint(equalToConstant: 28),
            switchContainer.heightAnchor.constraint(equalToConstant: 16),
            switchControl.centerXAnchor.constraint(equalTo: switchContainer.centerXAnchor),
            switchControl.centerYAnchor.constraint(equalTo: switchContainer.centerYAnchor),

            pillStack.topAnchor.constraint(equalTo: pillView.topAnchor, constant: 6),
            pillStack.bottomAnchor.constraint(equalTo: pillView.bottomAnchor, constant: -6),
            pillStack.leadingAnchor.constraint(equalTo: pillView.leadingAnchor, constant: 6),
            pillStack.trailingAnchor.constraint(equalTo: pillView.trailingAnchor, constant: -12),

            rowStack.topAnchor.constraint(equalTo: topAnchor),
            rowStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            rowStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            rowStack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    // MARK: - Render
    func configure(with state: ILReaderStateModel, palette: ILReaderPalette) {
        toggleLabel.text = state.autoScrollTitle
        noteLabel.text = state.keepAwakeNote
        hintLabel.text = state.hintText

        toggleLabel.textColor = palette.ink
        noteLabel.textColor = palette.subtle
        hintLabel.textColor = palette.subtle
        pillView.layer.borderColor = palette.line.cgColor
        switchControl.setOn(state.isAutoScrollEnabled, animated: false)
        // Off track uses the theme hairline (design: `autoBg` falls back to `th.line`).
        switchControl.backgroundColor = state.isAutoScrollEnabled ? .clear : palette.line
        switchControl.layer.cornerRadius = switchControl.bounds.height / 2
    }

    @objc private func handleToggle() {
        onToggle?()
    }
}
