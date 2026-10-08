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
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let pickButton = ILSanghaPillButton()

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
        nameLabel.font = ILTypography.rowTitle
        nameLabel.textColor = ILColors.ink
        subtitleLabel.font = ILTypography.subhead
        subtitleLabel.textColor = ILColors.inkTertiary
        subtitleLabel.numberOfLines = 2

        pickButton.configure(title: "sangha.row.pick".localized, style: .off)
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
