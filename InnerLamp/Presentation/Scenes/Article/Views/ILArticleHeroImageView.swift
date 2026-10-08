//
//  ILArticleHeroImageView.swift
//  InnerLamp
//

import UIKit

/// Ảnh hero màn Bài viết Phật pháp (cao 210pt, bo góc 22). Ảnh tải từ `image_url` của server
/// (hotlink từ trang gốc, có thể bị chặn/hỏng về sau); nền tint ấm với nhãn danh mục là placeholder
/// khi bài không có ảnh, đang tải hoặc tải lỗi.
final class ILArticleHeroImageView: UIView {

    // MARK: - UI Elements
    private let placeholderLabel = UILabel()
    private let imageView = ILRemoteImageView(frame: .zero)

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration
    func configure(category: String, imageURL: String?) {
        placeholderLabel.attributedText = ILTypography.makeEyebrow(text: category, color: ILColors.inkTertiary)
        imageView.setImage(urlString: imageURL)
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = ILColors.tint
        layer.cornerRadius = ILMetrics.radiusCardMedium
        clipsToBounds = true

        placeholderLabel.numberOfLines = 1
        placeholderLabel.textAlignment = .center
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false

        imageView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(placeholderLabel)
        addSubview(imageView)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 210),

            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            placeholderLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            placeholderLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            placeholderLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: ILMetrics.spaceStandard),
            placeholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -ILMetrics.spaceStandard)
        ])
    }
}
