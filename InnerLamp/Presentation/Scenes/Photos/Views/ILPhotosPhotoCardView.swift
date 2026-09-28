//
//  ILPhotosPhotoCardView.swift
//  InnerLamp
//

import UIKit

/// 1 thẻ ảnh trong lưới gallery "Ảnh chùa đẹp": ô ảnh bo góc (chiều cao theo ảnh) + tiêu đề Lora
/// + địa điểm. Chưa có ảnh thật (`image-slot` trong design handoff) nên ô ảnh dùng nền tint ấm
/// với nhãn danh mục làm placeholder, khớp ghi chú "cần ảnh thật từ phía sản phẩm" ở README.
final class ILPhotosPhotoCardView: UIView {

    // MARK: - Layout constants
    /// Khoảng cách từ ô ảnh tới tiêu đề và giữa tiêu đề/địa điểm.
    static let imageToTitleSpacing: CGFloat = 8
    static let titleToPlaceSpacing: CGFloat = 2

    // MARK: - UI Elements
    private let imageTile = UIView()
    private let categoryLabel = UILabel()
    private let titleLabel = UILabel()
    private let placeLabel = UILabel()
    private let stack = UIStackView()
    private var imageHeightConstraint: NSLayoutConstraint?

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration
    func configure(title: String, place: String, imageHeight: CGFloat, categoryLabel: String) {
        self.categoryLabel.text = categoryLabel
        self.titleLabel.text = title
        self.placeLabel.text = place
        imageHeightConstraint?.constant = imageHeight
    }

    // MARK: - Setup
    private func setupViews() {
        imageTile.translatesAutoresizingMaskIntoConstraints = false
        imageTile.backgroundColor = ILColors.tint2
        imageTile.layer.cornerRadius = ILMetrics.radiusCardSmall
        imageTile.clipsToBounds = true

        categoryLabel.font = ILTypography.caption
        categoryLabel.textColor = ILColors.inkMuted
        categoryLabel.textAlignment = .center
        categoryLabel.numberOfLines = 1
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = ILTypography.photoCaptionTitle
        titleLabel.textColor = ILColors.ink
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        placeLabel.font = ILTypography.label
        placeLabel.textColor = ILColors.inkTertiary
        placeLabel.numberOfLines = 1
        placeLabel.lineBreakMode = .byTruncatingTail

        imageTile.addSubview(categoryLabel)

        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = Self.titleToPlaceSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(imageTile)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(placeLabel)
        stack.setCustomSpacing(Self.imageToTitleSpacing, after: imageTile)

        addSubview(stack)

        let heightConstraint = imageTile.heightAnchor.constraint(equalToConstant: 0)
        imageHeightConstraint = heightConstraint

        NSLayoutConstraint.activate([
            heightConstraint,

            // Stack top-aligned (không pin bottom) để chú thích ngắn (1 dòng) không bị kéo giãn —
            // chiều cao thẻ do ô trong layout masonry quyết định, phần thừa chỉ là khoảng trống.
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),

            categoryLabel.centerXAnchor.constraint(equalTo: imageTile.centerXAnchor),
            categoryLabel.centerYAnchor.constraint(equalTo: imageTile.centerYAnchor)
        ])
    }
}
