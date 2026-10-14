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
    private lazy var imageTile: ILRemoteImageView = {
        let view = ILRemoteImageView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ILColors.tint2
        view.layer.cornerRadius = ILMetrics.radiusCardSmall
        view.clipsToBounds = true
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.photoCaptionTitle
        label.textColor = ILColors.ink
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()

    private lazy var placeLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.label
        label.textColor = ILColors.inkTertiary
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = Self.titleToPlaceSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

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
