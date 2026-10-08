//
//  ILPhotosPhotoCardView.swift
//  InnerLamp
//

import UIKit

/// 1 thẻ ảnh trong lưới gallery "Ảnh chùa đẹp": ô ảnh bo góc tỉ lệ cố định 4:3 (API không trả kích
/// thước ảnh — `AS-Photos-001`) + tiêu đề Lora + địa điểm. Ảnh tải qua `ILRemoteImageView`; nền
/// tint ấm của nó là placeholder.
final class ILPhotosPhotoCardView: UIView {

    // MARK: - Layout constants
    /// Khoảng cách từ ô ảnh tới tiêu đề và giữa tiêu đề/địa điểm.
    static let imageToTitleSpacing: CGFloat = 8
    static let titleToPlaceSpacing: CGFloat = 2
    /// Chiều cao / chiều rộng của ô ảnh.
    static let imageAspectRatio: CGFloat = 0.75

    // MARK: - UI Elements
    private let imageTile = ILRemoteImageView(frame: .zero)
    private let titleLabel = UILabel()
    private let placeLabel = UILabel()
    private let stack = UIStackView()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration
    /// `heroID` marks the image tile as the shared element of the photo viewer transition.
    func configure(title: String, place: String, thumbnailURL: String?, heroID: String) {
        imageTile.heroID = heroID
        titleLabel.text = title
        placeLabel.text = place
        imageTile.setImage(urlString: thumbnailURL)
    }

    // MARK: - Setup
    private func setupViews() {
        imageTile.translatesAutoresizingMaskIntoConstraints = false
        imageTile.backgroundColor = ILColors.tint2
        imageTile.layer.cornerRadius = ILMetrics.radiusCardSmall
        imageTile.clipsToBounds = true

        titleLabel.font = ILTypography.photoCaptionTitle
        titleLabel.textColor = ILColors.ink
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        placeLabel.font = ILTypography.label
        placeLabel.textColor = ILColors.inkTertiary
        placeLabel.numberOfLines = 1
        placeLabel.lineBreakMode = .byTruncatingTail

        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = Self.titleToPlaceSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(imageTile)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(placeLabel)
        stack.setCustomSpacing(Self.imageToTitleSpacing, after: imageTile)

        addSubview(stack)

        NSLayoutConstraint.activate([
            imageTile.heightAnchor.constraint(equalTo: imageTile.widthAnchor, multiplier: Self.imageAspectRatio),

            // Stack top-aligned (không pin bottom) để chú thích ngắn (1 dòng) không bị kéo giãn —
            // chiều cao thẻ do ô trong layout masonry quyết định, phần thừa chỉ là khoảng trống.
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}
