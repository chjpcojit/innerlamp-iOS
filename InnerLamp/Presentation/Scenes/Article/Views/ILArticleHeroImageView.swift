//
//  ILArticleHeroImageView.swift
//  InnerLamp
//

import UIKit

/// Ảnh hero màn Bài viết Phật pháp (cao 210pt, bo góc 22). Chưa có ảnh thật (`image-slot` trong
/// design handoff) nên ô ảnh dùng nền tint ấm với nhãn danh mục làm placeholder, khớp ghi chú
/// "cần ảnh thật từ phía sản phẩm" ở README.
final class ILArticleHeroImageView: UIView {

    // MARK: - UI Elements
    private let placeholderLabel = UILabel()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration
    func configure(category: String) {
        placeholderLabel.attributedText = ILTypography.makeEyebrow(text: category, color: ILColors.inkTertiary)
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

        addSubview(placeholderLabel)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 210),

            placeholderLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            placeholderLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            placeholderLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: ILMetrics.spaceStandard),
            placeholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -ILMetrics.spaceStandard)
        ])
    }
}
