//
//  ILSanghaMyTempleCardView.swift
//  InnerLamp
//

import UIKit

/// Thẻ "Chùa tu tập của tôi": ảnh bìa (140pt, nền placeholder khi chưa có ảnh), tên + địa chỉ, pill trạng thái mở cửa,
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
    private lazy var coverView: ILRemoteImageView = {
        let view = ILRemoteImageView(frame: .zero)
        view.backgroundColor = ILColors.sunk2
        view.isUserInteractionEnabled = false
        return view
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.templeCardTitle
        label.textColor = ILColors.ink
        label.numberOfLines = 0
        return label
    }()

    private lazy var placeLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.note
        label.textColor = ILColors.inkTertiary
        label.numberOfLines = 0
        return label
    }()

    private lazy var statusPill: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 14
        view.layer.borderWidth = 1
        view.layer.borderColor = ILColors.border.cgColor
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        return view
    }()

    private lazy var statusDot: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Layout.statusDotSize / 2
        return view
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subheadMedium
        label.textColor = ILColors.inkSecondary
        return label
    }()

    private lazy var abbotLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.note
        label.textColor = ILColors.inkTertiary
        label.numberOfLines = 0
        return label
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
    func configure(with model: ILSanghaMyTempleModel) {
        nameLabel.text = model.name
        placeLabel.text = model.place
        abbotLabel.text = model.abbotText
        statusPill.isHidden = model.statusText.isEmpty
        statusLabel.text = model.statusText
        statusDot.backgroundColor = model.isOpen ? ILColors.green : ILColors.inkFaint
        coverView.setImage(urlString: model.imageURL)
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardRegular
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor
        clipsToBounds = true

        coverView.heightAnchor.constraint(equalToConstant: Layout.coverHeight).isActive = true

        statusDot.widthAnchor.constraint(equalToConstant: Layout.statusDotSize).isActive = true
        statusDot.heightAnchor.constraint(equalToConstant: Layout.statusDotSize).isActive = true
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
