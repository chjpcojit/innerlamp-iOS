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
    private lazy var pillView: UIControl = {
        let v = UIControl()
        v.layer.cornerRadius = 15
        v.layer.borderWidth = 1
        return v
    }()
    private lazy var switchContainer: UIView = {
        let v = UIView()
        return v
    }()
    // The design toggle is 28×16pt; a `UISwitch` is 51×31pt, so scale it inside a fixed box.
    private lazy var switchControl: UISwitch = {
        let v = UISwitch()
        v.onTintColor = ILColors.gold
        v.transform = CGAffineTransform(scaleX: 28.0 / 51.0, y: 28.0 / 51.0)
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var toggleLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.subheadMedium
        return v
    }()
    private lazy var noteLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.label
        return v
    }()
    private lazy var hintLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.label
        v.textAlignment = .right
        v.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return v
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
        pillView.addTarget(self, action: #selector(handleToggle), for: .touchUpInside)

        switchContainer.addSubview(switchControl)

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
