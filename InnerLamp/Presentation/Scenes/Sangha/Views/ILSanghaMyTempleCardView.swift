//
//  ILSanghaMyTempleCardView.swift
//  InnerLamp
//

import UIKit

/// Thẻ "Chùa tu tập của tôi": ảnh bìa (placeholder 140pt), tên + địa chỉ, pill trạng thái mở cửa,
/// hairline rồi dòng "Trụ trì: …". Cả thẻ là 1 vùng chạm mở Trang chùa.
final class ILSanghaMyTempleCardView: UIControl {

    private enum Layout {
        static let coverHeight: CGFloat = 140
        static let padding: CGFloat = 16
        static let statusDotSize: CGFloat = 7
    }

    // MARK: - Properties
    var onTap: (() -> Void)?

    // MARK: - UI Elements
    private let coverView = UIView()
    private let nameLabel = UILabel()
    private let placeLabel = UILabel()
    private let statusPill = UIView()
    private let statusDot = UIView()
    private let statusLabel = UILabel()
    private let abbotLabel = UILabel()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    func configure(with model: ILSanghaMyTempleModel) {
        nameLabel.text = model.name
        placeLabel.text = model.place
        abbotLabel.text = model.abbotText
        statusPill.isHidden = model.statusText.isEmpty
        statusLabel.text = model.statusText
        statusDot.backgroundColor = model.isOpen ? ILColors.green : ILColors.inkFaint
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardRegular
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor
        clipsToBounds = true

        coverView.backgroundColor = ILColors.sunk2
        coverView.isUserInteractionEnabled = false
        coverView.heightAnchor.constraint(equalToConstant: Layout.coverHeight).isActive = true

        nameLabel.font = ILTypography.templeCardTitle
        nameLabel.textColor = ILColors.ink
        nameLabel.numberOfLines = 0
        placeLabel.font = ILTypography.note
        placeLabel.textColor = ILColors.inkTertiary
        placeLabel.numberOfLines = 0

        statusDot.layer.cornerRadius = Layout.statusDotSize / 2
        statusDot.widthAnchor.constraint(equalToConstant: Layout.statusDotSize).isActive = true
        statusDot.heightAnchor.constraint(equalToConstant: Layout.statusDotSize).isActive = true
        statusLabel.font = ILTypography.subheadMedium
        statusLabel.textColor = ILColors.inkSecondary
        let statusStack = UIStackView(arrangedSubviews: [statusDot, statusLabel])
        statusStack.axis = .horizontal
        statusStack.alignment = .center
        statusStack.spacing = 6
        statusStack.translatesAutoresizingMaskIntoConstraints = false
        statusPill.addSubview(statusStack)
        NSLayoutConstraint.activate([
            statusStack.topAnchor.constraint(equalTo: statusPill.topAnchor, constant: 5),
            statusStack.bottomAnchor.constraint(equalTo: statusPill.bottomAnchor, constant: -5),
            statusStack.leadingAnchor.constraint(equalTo: statusPill.leadingAnchor, constant: 10),
            statusStack.trailingAnchor.constraint(equalTo: statusPill.trailingAnchor, constant: -10)
        ])
        statusPill.layer.cornerRadius = 14
        statusPill.layer.borderWidth = 1
        statusPill.layer.borderColor = ILColors.border.cgColor
        statusPill.setContentHuggingPriority(.required, for: .horizontal)
        statusPill.setContentCompressionResistancePriority(.required, for: .horizontal)

        let titleStack = UIStackView(arrangedSubviews: [nameLabel, placeLabel])
        titleStack.axis = .vertical
        titleStack.spacing = 4

        let headRow = UIStackView(arrangedSubviews: [titleStack, statusPill])
        headRow.axis = .horizontal
        headRow.alignment = .top
        headRow.spacing = ILMetrics.spaceMedium - 2

        let divider = UIView()
        divider.backgroundColor = ILColors.border
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true

        abbotLabel.font = ILTypography.note
        abbotLabel.textColor = ILColors.inkTertiary
        abbotLabel.numberOfLines = 0

        let infoStack = UIStackView(arrangedSubviews: [headRow, divider, abbotLabel])
        infoStack.axis = .vertical
        infoStack.spacing = ILMetrics.spaceMedium - 2
        infoStack.isLayoutMarginsRelativeArrangement = true
        infoStack.layoutMargins = UIEdgeInsets(
            top: Layout.padding, left: Layout.padding, bottom: Layout.padding, right: Layout.padding
        )

        let contentStack = UIStackView(arrangedSubviews: [coverView, infoStack])
        contentStack.axis = .vertical
        contentStack.isUserInteractionEnabled = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)

        // `layer.borderColor` là CGColor tĩnh — refresh thủ công khi đổi light/dark.
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.layer.borderColor = ILColors.border.cgColor
            self.statusPill.layer.borderColor = ILColors.border.cgColor
        }
    }

    @objc private func handleTapAction() {
        onTap?()
    }
}
