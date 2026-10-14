//
//  ILSanghaTempleRowView.swift
//  InnerLamp
//

import UIKit

/// Hàng "Chùa gần bạn": tên + địa chỉ bên trái, nút pill "Chọn" bên phải. Chạm hàng mở Trang
/// chùa; chạm "Chọn" đặt làm chùa tu tập.
final class ILSanghaTempleRowView: UIView {

    // MARK: - Properties
    var onTap: (() -> Void)?
    var onPick: (() -> Void)?

    // MARK: - UI Elements
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.rowTitle
        label.textColor = ILColors.ink
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.inkTertiary
        label.numberOfLines = 2
        return label
    }()

    private lazy var pickButton: ILSanghaPillButton = {
        let button = ILSanghaPillButton()
        button.configure(title: "sangha.row.pick".localized, style: .off)
        return button
    }()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    func configure(with model: ILSanghaNearbyRowModel) {
        nameLabel.text = model.name
        subtitleLabel.text = model.subtitle
    }

    // MARK: - Setup
    private func setupViews() {
        pickButton.addTarget(self, action: #selector(handlePick), for: .touchUpInside)

        let textStack = UIStackView(arrangedSubviews: [nameLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 3

        let row = UIStackView(arrangedSubviews: [textStack, pickButton])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = ILMetrics.spaceMedium - 2
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor, constant: ILMetrics.spaceMedium),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -ILMetrics.spaceMedium),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.spaceStandard),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.spaceStandard)
        ])

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }

    // MARK: - Actions
    @objc private func handleTap() {
        onTap?()
    }

    @objc private func handlePick() {
        onPick?()
    }
}
